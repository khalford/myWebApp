# Database serving VM provisioning

resource "openstack_compute_instance_v2" "db_vm" {
        name  = "db-vm"
        image_id        = var.vm_image_id
        flavor_id       = var.vm_flavor_id
        security_groups = ["default", openstack_networking_secgroup_v2.db_secgroup.name]
        key_pair        = var.ssh_public_key_name
    
    network {
        name = openstack_networking_network_v2.webapp_network.name
        #name = "internal"
    }

    metadata = {
        group = "db-vms"
    }
}

# Web serving VM provisioning

resource "openstack_compute_instance_v2" "web_vm" {
        count = var.no_web_vms
        name  = "web-vm-${count.index}"
        image_id        = var.vm_image_id
        flavor_id       = var.vm_flavor_id
        security_groups = ["default", openstack_networking_secgroup_v2.http_secgroup.name]
        key_pair        = var.ssh_public_key_name
    
    network {
        name = openstack_networking_network_v2.webapp_network.name
        #name = "internal"
    }

    metadata = {
        group = "web-vms"
    }
}