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

locals {
  count = 2
  count_set = toset([for v in range(local.count) : tostring(v)])
}

data "openstack_images_image_v2" "ubuntu-2004-nogui" {
 		  name            = "ubuntu-focal-20.04-nogui"
		  most_recent = true
		}

data "openstack_compute_flavor_v2" "vm_flavor" {
		  name = "l3.nano"
		}

resource "openstack_lb_loadbalancer_v2" "web_loadbalancer" {
  name = "web-loadbalancer"
  vip_subnet_id = "81fa79ee-5324-42c4-a136-ae012fac84b2"
}

resource "openstack_lb_listener_v2" "http_listener" {
  name = "http"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web_loadbalancer.id}"
}

resource "openstack_lb_pool_v2" "web_pool" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.http_listener.id}"
}

resource "openstack_compute_instance_v2" "web_vm" {
        count = local.count
        name  = "web-vm-${count.index}"
        image_id        = data.openstack_images_image_v2.ubuntu-2004-nogui.id
        flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.flavor_id
        security_groups = ["default", "HTTP"]
        key_pair        = "ansible-instance"
    
    network {
        name = "Internal"
    }

    metadata = {
        group = "web-vm"
    }

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i openstack.yml -l ${self.name} deploy_webserver.yaml"

    }
}

data "openstack_compute_instance_v2" "web_vm_data" {
  for_each = local.count_set
  id = "${openstack_compute_instance_v2.web_vm[each.key].id}"
}

resource "openstack_lb_member_v2" "web_member" {
  for_each = local.count_set
  pool_id       = "${openstack_lb_pool_v2.web_pool.id}"
  address       = "${data.openstack_compute_instance_v2.web_vm_data[each.key].access_ip_v4}"
  protocol_port = 80
}