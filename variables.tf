variable "no_web_vms" {
  description = "The number of web serving VMs to create."
  type = number
  default = 1
}

variable "lb_float_ip" {
  description = "The floating ip to associate to the load balancer."
  type = string 
}

variable "external_network" {
    description = "The name of the external network in your project."
    type = string
    default = "External"
}

variable "ssh_public_key_name" {
  description = "The name of your SSH Key Pair on Openstack."
  type = string
}

variable "subnet_cidr" {
    description = "The CIDR block range for IP addresses on the network."
    type = string
    default = "192.168.100.0/24"
}

variable "vm_image" {
  description = "The name of the image to build the VM from. Can be found with 'openstack image list'."
  type = string
  default = "ubuntu-focal-20.04-nogui"
}

variable "vm_flavor" {
    description = "The name of the flavor to build the VM on. Can be found with 'openstack flavor list'."
    type = string
    default = "l3.nano"
}

variable "fed_id" {
  description = "Your Fed ID used in the clouds.yaml."
  type = string
}