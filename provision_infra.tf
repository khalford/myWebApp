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

# Local variables - Should be changed by User

locals {
  web_count = 3
  db_count = 1
  web_count_set = toset([for v in range(local.web_count) : tostring(v)])
  db_count_set = toset([for v in range(local.db_count) : tostring(v)])
  lb_float_ip = ""
  external_network_id = ""
  ssh_key_name = ""
}

# Note: Ansible is configured to run on Ubuntu 20. Changing the image may affect Ansible configuration
data "openstack_images_image_v2" "ubuntu-2004-nogui" {
 		  name            = "ubuntu-focal-20.04-nogui"
		  most_recent = true
		}

data "openstack_compute_flavor_v2" "vm_flavor" {
		  name = "l3.nano"
		}

# Network set up

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
  external_network_id = local.external_network_id
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

# Create security groups

resource "openstack_networking_secgroup_v2" "http_secgroup" {
  name        = "web-HTTP"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "http_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.http_secgroup.id
  protocol = "tcp"
  port_range_min = 80
  port_range_max = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "db_secgroup" {
  name        = "SQLDB"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "db_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.db_secgroup.id
  protocol = "tcp"
  port_range_min = 3306
  port_range_max = 3306
  remote_group_id = openstack_networking_secgroup_rule_v2.http_secgroup_rule.id
}

# Web serving VM provisioning

resource "openstack_compute_instance_v2" "web_vm" {
        count = local.web_count
        name  = "web-vm-${count.index}"
        image_id        = data.openstack_images_image_v2.ubuntu-2004-nogui.id
        flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.flavor_id
        security_groups = ["default", "web-HTTP"]
        key_pair        = local.ssh_key_name
        depends_on = [ openstack_networking_router_interface_v2.router_interface_1 ]
    
    network {
        name = openstack_networking_network_v2.network_1.name
        #name = "internal"
    }

    metadata = {
        group = "web-vms"
    }
}

# Database serving VM provisioning

resource "openstack_compute_instance_v2" "db_vm" {
        count = local.db_count
        name  = "db-vm-${count.index}"
        image_id        = data.openstack_images_image_v2.ubuntu-2004-nogui.id
        flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.flavor_id
        security_groups = ["default", "SQLDB"]
        key_pair        = local.ssh_key_name
    
    network {
        name = openstack_networking_network_v2.network_1.name
        #name = "internal"
    }

    metadata = {
        group = "db-vms"
    }
}

# Getting VM ids into data resources

data "openstack_compute_instance_v2" "web_vm_data" {
  for_each = local.web_count_set
  id = "${openstack_compute_instance_v2.web_vm[each.key].id}"
}

data "openstack_compute_instance_v2" "db_vm_data" {
  for_each = local.db_count_set
  id = "${openstack_compute_instance_v2.db_vm[each.key].id}"
}

# Load balancer provisioning

resource "openstack_lb_loadbalancer_v2" "web_loadbalancer" {
  name = "web-loadbalancer"
  vip_subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_networking_floatingip_associate_v2" "lb_fip" {
  floating_ip = local.lb_float_ip
  port_id = openstack_lb_loadbalancer_v2.web_loadbalancer.vip_port_id
}

# HTTP listener, pool and memeber provisioning

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
  for_each = local.web_count_set
  pool_id       = "${openstack_lb_pool_v2.http_pool.id}"
  address       = "${data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4}"
  protocol_port = 80
}

# SSH listener, pool and member provisioning

resource "openstack_lb_listener_v2" "web_ssh_listener" {
  for_each = local.web_count_set
  name = "${data.openstack_compute_instance_v2.web_vm_data[each.key].name}-ssh"
  protocol        = "TCP"
  protocol_port   = 1000 + tonumber(split(".", data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4)[3])
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web_loadbalancer.id}"
}

resource "openstack_lb_pool_v2" "web_ssh_pool" {
  for_each = local.web_count_set
  protocol    = "TCP"
  lb_method   = "SOURCE_IP"
  listener_id = "${openstack_lb_listener_v2.web_ssh_listener[each.key].id}"
}

resource "openstack_lb_member_v2" "web_ssh_member" {
  for_each = local.web_count_set
  pool_id       = "${openstack_lb_pool_v2.web_ssh_pool[each.key].id}"
  address       = "${data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4}"
  protocol_port = 22
}

resource "openstack_lb_listener_v2" "db_ssh_listener" {
  for_each = local.db_count_set
  name = "${data.openstack_compute_instance_v2.db_vm_data[each.key].name}-ssh"
  protocol        = "TCP"
  protocol_port   = 1000 + tonumber(split(".", data.openstack_compute_instance_v2.db_vm_data[each.key].access_ip_v4)[3])
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web_loadbalancer.id}"
}

resource "openstack_lb_pool_v2" "db_ssh_pool" {
  for_each = local.db_count_set
  protocol    = "TCP"
  lb_method   = "SOURCE_IP"
  listener_id = "${openstack_lb_listener_v2.db_ssh_listener[each.key].id}"
}

resource "openstack_lb_member_v2" "db_ssh_member" {
  for_each = local.db_count_set
  pool_id       = "${openstack_lb_pool_v2.db_ssh_pool[each.key].id}"
  address       = "${data.openstack_compute_instance_v2.db_vm_data[each.key].access_ip_v4}"
  protocol_port = 22
}

# Run Ansible config on Web serving VMs

resource "null_resource" "ansible_web_config" {
  for_each = local.web_count_set
  depends_on = [openstack_networking_floatingip_associate_v2.lb_fip, openstack_compute_instance_v2.web_vm]
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=${openstack_lb_listener_v2.web_ssh_listener[each.key].protocol_port} lb_fip=${local.lb_float_ip}' -i ${local.lb_float_ip},  deploy_webserver.yaml"
  }
}

# Run Ansible config on Database serving VMs

resource "null_resource" "ansible_database_config" {
  for_each = local.db_count_set
  depends_on = [openstack_networking_floatingip_associate_v2.lb_fip, openstack_compute_instance_v2.db_vm]
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=${openstack_lb_listener_v2.db_ssh_listener[each.key].protocol_port}' -i ${local.lb_float_ip},  deploy_database.yaml"
  }
}