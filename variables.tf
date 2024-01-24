variable "no_web_vms" {
  description = "The number of web serving VMs to create."
  type = number
}

variable "lb_float_ip" {
  description = "The floating ip to associate to the load balancer."
  type = string 
}

variable "external_network_id" {
    description = "The UUID of the external network in your project."
    type = string
}

variable "ssh_public_key_name" {
  description = "The name of your SSH Key Pair on Openstack."
  type = string
}

variable "subnet_cidr" {
    description = "The CIDR block range for IP addresses on the network."
    type = string
}

variable "vm_image_id" {
  description = "The UUID of the image to build the VM from. Can be found with 'openstack image list'.\n The default image is 'Ubuntu-20.04-nogui'."
  type = string
}

variable "vm_flavor_id" {
    description = "The UUID of the flavor to build the VM on. Can be found with 'openstack flavor list'.\n  The default flavor is 'l3.nano'."
    type = string
}

variable "fed_id" {
  description = "Your Fed ID used in the clouds.yaml."
  type = string
}