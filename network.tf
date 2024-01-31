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

# Creating the private network on Openstack and routing it to the external network

resource "openstack_networking_network_v2" "webapp_network" {
  name = "webapp-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "webapp_subnet" {
  name = "webapp-subnet"
  network_id = openstack_networking_network_v2.webapp_network.id
  cidr = var.subnet_cidr
  ip_version = 4
}

resource "openstack_networking_router_v2" "webapp_router" {
  name = "webapp-router"
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "webapp_router_interface" {
  router_id = openstack_networking_router_v2.webapp_router.id
  subnet_id = openstack_networking_subnet_v2.webapp_subnet.id
}

# Create HTTP and SQL security groups

resource "openstack_networking_secgroup_v2" "http_secgroup" {
  name        = "webapp-HTTP"
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
  remote_ip_prefix = var.subnet_cidr
}

# Creating the loadbalancer and associating a floating IP

resource "openstack_lb_loadbalancer_v2" "webapp_loadbalancer" {
  name = "webapp-loadbalancer"
  vip_subnet_id = openstack_networking_subnet_v2.webapp_subnet.id
}

resource "openstack_networking_floatingip_associate_v2" "lb_fip" {
  floating_ip = var.lb_float_ip
  port_id = openstack_lb_loadbalancer_v2.webapp_loadbalancer.vip_port_id
}

# Creating loadbalancer listeners, pools and adding the VM as a member

resource "openstack_lb_listener_v2" "http_listener" {
  name = "http"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.webapp_loadbalancer.id
}

resource "openstack_lb_pool_v2" "http_pool" {
  name = "http-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.http_listener.id
}

resource "openstack_lb_member_v2" "http_member" {
  # for_each = openstack_compute_instance_v2.web_vm
  count = length(openstack_compute_instance_v2.web_vm)
  pool_id       = openstack_lb_pool_v2.http_pool.id
  address       = openstack_compute_instance_v2.web_vm[count.index].access_ip_v4
  protocol_port = 80
}

resource "openstack_lb_listener_v2" "ssh_listener" {
  name = "bastion-ssh"
  protocol        = "TCP"
  protocol_port   = 2222
  loadbalancer_id = openstack_lb_loadbalancer_v2.webapp_loadbalancer.id
  timeout_client_data = 600000
  timeout_member_connect = 600000
  timeout_member_data = 600000
}

resource "openstack_lb_pool_v2" "ssh_pool" {
  name = "ssl-pool"
  protocol    = "TCP"
  lb_method   = "SOURCE_IP"
  listener_id = openstack_lb_listener_v2.ssh_listener.id
}

resource "openstack_lb_member_v2" "ssh_member" {
  pool_id       = openstack_lb_pool_v2.ssh_pool.id
  address       = openstack_compute_instance_v2.bastion_vm.access_ip_v4
  protocol_port = 22
}