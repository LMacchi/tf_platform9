# OS config is read from environment variables
provider "openstack" {}

variable "agents" {
  default = "1"
}

data "template_file" "master_userdata" {
  template = "${file("${path.module}/templates/master_userdata.tpl")}"
  vars {
    url    = "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver=latest"
  }
}

data "template_file" "agent_userdata" {
  count    = "${var.agents}"
  template = "${file("${path.module}/templates/agent_userdata.tpl")}"

  vars {
    hostname  = "agent${count.index}"
    fqdn      = "agent${count.index}.platform9.puppet.net"
  }
}

resource "openstack_compute_instance_v2" "master" {
  name            = "master"
  flavor_id       = "4"
  key_pair        = "puppet_laptop"
  security_groups = ["default"]
  user_data       = "${data.template_file.master_userdata.rendered}"

  block_device {
    uuid                  = "667d85ac-1d1e-a494-4017-437858a3da17"
    source_type           = "image"
    volume_size           = 80
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "network1"
  }

}

resource "openstack_networking_floatingip_v2" "master" {
  pool = "external"
}

resource "openstack_compute_floatingip_associate_v2" "master" {
  floating_ip = "${openstack_networking_floatingip_v2.master.address}"
  instance_id = "${openstack_compute_instance_v2.master.id}"

  connection {
    host        = "${openstack_networking_floatingip_v2.master.address}"
    type        = "ssh"
    user        = "centos"
    private_key = "${file("${path.module}/files/lmacchi_private_key.rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/centos/puppet_scripts",
    ]
  }

  provisioner "file" {
    source      = "files/custom-pe.conf"
    destination = "/home/centos/custom-pe.conf"
  }

  provisioner "file" {
    source      = "files/master_csr_attributes.yaml"
    destination = "/home/centos/csr_attributes.yaml"
  }

  provisioner "file" {
    source      = "files/puppet_scripts"
    destination = "/home/centos"
  }
  
}

resource "openstack_compute_instance_v2" "agent" {
  name            = "agent${count.index}"
  flavor_id       = "2"
  key_pair        = "puppet_laptop"
  security_groups = ["default"]
  user_data       = "${element(data.template_file.agent_userdata.*.rendered, count.index)}"
  count           = "${var.agents}"

  block_device {
    uuid                  = "667d85ac-1d1e-a494-4017-437858a3da17"
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "network1"
  }
}

resource "openstack_networking_floatingip_v2" "agent" {
  pool  = "external"
  count = "${var.agents}"
}

resource "openstack_compute_floatingip_associate_v2" "agents" {
  floating_ip = "${element(openstack_networking_floatingip_v2.agent.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.agent.*.id, count.index)}"
  count       = "${var.agents}"

  
}

