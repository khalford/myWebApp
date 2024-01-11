terraform {
			required_version = ">= 0.14.0"
			  required_providers {
			    openstack = {
			      source  = "terraform-provider-openstack/openstack"
			      version = "~> 1.53.0"
			    }
			  }
			}

provider "openstack" {
    cloud = "openstack"	# Uses the section called “openstack” from our app creds
}

resource "openstack_networking_network_v2" "network_1" {
  name = "web-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name = "vm-subnet"
  network_id = openstack_networking_network_v2.network_1.id
  cidr = "192.168.100.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router_1" {
  name = "web-router"
  external_network_id = "5283f642-8bd8-48b6-8608-fa3006ff4539"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

locals {
  count = 2
  count_set = toset([for v in range(local.count) : tostring(v)])
  floating_ip = ""
}

data "openstack_images_image_v2" "ubuntu-2004-nogui" {
 		  name            = "ubuntu-focal-20.04-nogui"
		  most_recent = true
		}

data "openstack_compute_flavor_v2" "vm_flavor" {
		  name = "l3.nano"
		}

resource "openstack_compute_instance_v2" "web_vm" {
        count = local.count
        name  = "web-vm-${count.index}"
        image_id        = data.openstack_images_image_v2.ubuntu-2004-nogui.id
        flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.flavor_id
        security_groups = ["default", "HTTP"]
        key_pair        = "ansible-instance-pubkey"
    
    network {
        name = openstack_networking_network_v2.network_1.name
        #name = "internal"
    }

    metadata = {
        group = "web-vms"
    }
}

data "openstack_compute_instance_v2" "web_vm_data" {
  for_each = local.count_set
  id = "${openstack_compute_instance_v2.web_vm[each.key].id}"
}

resource "null_resource" "run_ansible_on_vms" {
  for_each = local.count_set
  depends_on = [openstack_networking_floatingip_associate_v2.lb_fip, openstack_compute_instance_v2.web_vm]
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=${openstack_lb_listener_v2.ssh_listener[each.key].protocol_port}' -i ${local.floating_ip},  deploy_webserver.yaml"
  }
}

resource "openstack_lb_loadbalancer_v2" "web_loadbalancer" {
  name = "web-loadbalancer"
  vip_subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_lb_listener_v2" "http_listener" {
  name = "http"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web_loadbalancer.id}"
}

resource "openstack_lb_pool_v2" "http_pool" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.http_listener.id}"
}

resource "openstack_lb_member_v2" "http_member" {
  for_each = local.count_set
  pool_id       = "${openstack_lb_pool_v2.http_pool.id}"
  address       = "${data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4}"
  protocol_port = 80
}

resource "openstack_lb_listener_v2" "ssh_listener" {
  for_each = local.count_set
  name = "${data.openstack_compute_instance_v2.web_vm_data[each.key].name}-ssh"
  protocol        = "TCP"
  protocol_port   = 1000 + tonumber(split(".", data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4)[3])
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web_loadbalancer.id}"
}

resource "openstack_lb_pool_v2" "ssh_pool" {
  for_each = local.count_set
  protocol    = "TCP"
  lb_method   = "SOURCE_IP"
  listener_id = "${openstack_lb_listener_v2.ssh_listener[each.key].id}"
}

resource "openstack_lb_member_v2" "ssh_member" {
  for_each = local.count_set
  pool_id       = "${openstack_lb_pool_v2.ssh_pool[each.key].id}"
  address       = "${data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4}"
  protocol_port = 22
}

resource "openstack_networking_floatingip_associate_v2" "lb_fip" {
  floating_ip = local.floating_ip
  port_id = openstack_lb_loadbalancer_v2.web_loadbalancer.vip_port_id
}