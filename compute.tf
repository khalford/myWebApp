# Database serving VM provisioning

resource "openstack_compute_keypair_v2" "bastion_key" {
  name = "bastion_key"
}

resource "local_file" "bastion-key" {
  content  = openstack_compute_keypair_v2.bastion_key.private_key
  filename = "./bastion_key"
}

resource "openstack_compute_instance_v2" "bastion_vm" {
        name  = "bastion-vm"
        image_name        = var.vm_image
        flavor_name       = var.vm_flavor
        security_groups = ["default"]
        key_pair        = var.ssh_public_key_name
    
    network {
        name = openstack_networking_network_v2.webapp_network.name
    }

    

}

resource "null_resource" "bastion_config" {
    depends_on = [ 
        openstack_lb_member_v2.ssh_member,
        openstack_compute_instance_v2.bastion_vm,
        openstack_networking_floatingip_associate_v2.lb_fip,
        openstack_networking_router_interface_v2.webapp_router_interface
        ]
    provisioner "file" {
            source      = "./bastion_key"
            destination = "/home/${var.fed_id}/.ssh/id_rsa"

            connection {
                type     = "ssh"
                user     = "${var.fed_id}"
                private_key = file("/home/${var.fed_id}/.ssh/id_rsa")
                host     = var.lb_float_ip
                port = 2222
                timeout = "60s"
            }
        }
        
    provisioner "remote-exec" {
      inline = [ "sudo chmod 600 /home/${var.fed_id}/.ssh/id_rsa" ]

      connection {
                type     = "ssh"
                user     = "${var.fed_id}"
                private_key = file("/home/${var.fed_id}/.ssh/id_rsa")
                host     = var.lb_float_ip
                port = 2222
                timeout = "60s"
            }
    }

    provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=2222 lb_fip=${var.lb_float_ip} fed_id=${var.fed_id}' -i ${var.lb_float_ip}, play.yaml"
        }
}


resource "openstack_compute_instance_v2" "db_vm" {
        name  = "db-vm"
        image_name        = var.vm_image
        flavor_name       = var.vm_flavor
        security_groups = ["default", openstack_networking_secgroup_v2.db_secgroup.name]
        key_pair        = openstack_compute_keypair_v2.bastion_key.name
    
    network {
        name = openstack_networking_network_v2.webapp_network.name
    }

    metadata = {
        group = "db_vms"
    }
}

# Web serving VM provisioning

resource "openstack_compute_instance_v2" "web_vm" {
        count = var.no_web_vms
        name  = "web-vm-${count.index}"
        image_name        = var.vm_image
        flavor_name       = var.vm_flavor
        security_groups = ["default", openstack_networking_secgroup_v2.http_secgroup.name]
        key_pair        = openstack_compute_keypair_v2.bastion_key.name
    
    network {
        name = openstack_networking_network_v2.webapp_network.name
    }

    metadata = {
        group = "web_vms"
    }
}