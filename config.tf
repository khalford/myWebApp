resource "null_resource" "run_ansible_on_db" {
  depends_on = [ openstack_compute_instance_v2.db_vm, openstack_lb_member_v2.db_ssh_member ]
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=${openstack_lb_listener_v2.db_ssh_listener.protocol_port} db_ip=${openstack_compute_instance_v2.db_vm.access_ip_v4}' -i ${var.lb_float_ip}, deploy_database.yaml"
  }
}

resource "null_resource" "run_ansible_on_web" {
  depends_on = [ openstack_compute_instance_v2.web_vm, openstack_lb_member_v2.web_ssh_member ]
  count = length(openstack_compute_instance_v2.web_vm)
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -e 'ansible_port=${openstack_lb_listener_v2.web_ssh_listener[count.index].protocol_port} lb_fip=${var.lb_float_ip} db_ip=${openstack_compute_instance_v2.db_vm.access_ip_v4}' -i ${var.lb_float_ip}, deploy_webserver.yaml"
  }
}