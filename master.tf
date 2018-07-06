# OS config is read from environment variables
provider "openstack" {}

# Variable to control infrastructure nodes
variable "agents" {
  default = "2"
}
variable "cms" {
  default = "0"
}

# Variables to configure Puppet master and agents
variable "domain" {
  default = "platform9.puppet.net"
}
variable "autosign_pwd" {
  default = "S3cr3tP@ssw0rd!"
}
variable "console_pwd" {
  default = "puppetlabs"
}
variable "r10k_remote" {
  default = "https://github.com/LMacchi/my-control-repo.git"
}

# Openstack variables
variable "ssh_priv_key_path" {
  default = "files/lmacchi_private_key.rsa"
}

# File templates
data "template_file" "custom_pe_conf" {
  template = "${file("${path.module}/templates/custom_pe.conf.tpl")}"
  vars {
    console_pwd = "${var.console_pwd}"
    r10k_remote = "${var.r10k_remote}"
    domain      = "${var.domain}"
  }
}

data "template_file" "master_userdata" {
  template = "${file("${path.module}/templates/master_userdata.tpl")}"
  vars {
    domain = "${var.domain}"
  }
}

data "template_file" "provision_master_script" {
  template = "${file("${path.module}/templates/provision_master.sh.tpl")}"
  vars {
    url    = "https://pm.puppetlabs.com/cgi-bin/download.cgi?dist=el&rel=7&arch=x86_64&ver="
    pe_ver = "latest"
    domain = "${var.domain}"
  }
}

data "template_file" "agent_userdata" {
  count    = "${var.agents}"
  template = "${file("${path.module}/templates/agent_userdata.tpl")}"

  vars {
    hostname     = "agent${count.index}"
    role         = "agent"
    domain       = "${var.domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

data "template_file" "cm_userdata" {
  count    = "${var.cms}"
  template = "${file("${path.module}/templates/cm_userdata.tpl")}"

  vars {
    hostname     = "cm${count.index}"
    role         = "puppet::cm"
    domain       = "${var.domain}"
    autosign_pwd = "${var.autosign_pwd}"
  }
}

# Master resources
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
    private_key = "${file("${path.module}/${var.ssh_priv_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/centos/puppet_scripts",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.custom_pe_conf.rendered}"
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

  provisioner "file" {
    content     = "${data.template_file.provision_master_script.rendered}"
    destination = "/home/centos/puppet_scripts/provision_master.sh"
  }

  # Move master provisioning to remote-exec to allow master to
  # be fully provisioned before creating nodes
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/centos/puppet_scripts/*.sh",
      "sudo /home/centos/puppet_scripts/provision_master.sh",
    ]
  }
}

# Agents resources
resource "openstack_compute_instance_v2" "agent" {
  name            = "agent${count.index}"
  flavor_id       = "2"
  key_pair        = "puppet_laptop"
  security_groups = ["default"]
  user_data       = "${element(data.template_file.agent_userdata.*.rendered, count.index)}"
  count           = "${var.agents}"
  depends_on      = ["openstack_compute_floatingip_associate_v2.master"]

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

# Compile Masters resources
resource "openstack_compute_instance_v2" "cm" {
  name            = "cm${count.index}"
  flavor_id       = "3"
  key_pair        = "puppet_laptop"
  security_groups = ["default"]
  user_data       = "${element(data.template_file.cm_userdata.*.rendered, count.index)}"
  count           = "${var.cms}"
  depends_on      = ["openstack_compute_floatingip_associate_v2.master"]

  block_device {
    uuid                  = "667d85ac-1d1e-a494-4017-437858a3da17"
    source_type           = "image"
    volume_size           = 40
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "network1"
  }
}

resource "openstack_networking_floatingip_v2" "cm" {
  pool  = "external"
  count = "${var.cms}"
}

resource "openstack_compute_floatingip_associate_v2" "cm" {
  floating_ip = "${element(openstack_networking_floatingip_v2.cm.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.cm.*.id, count.index)}"
  count       = "${var.cms}"

  connection {
    host        = "${openstack_networking_floatingip_v2.master.address}"
    type        = "ssh"
    user        = "centos"
    private_key = "${file("${path.module}/${var.ssh_priv_key_path}")}"
  }

  # Sign CM certificate in master
  provisioner "remote-exec" {
    inline = [<<EOF
while [[ ! -e $(sudo puppet master --configprint csrdir)/cm${count.index}.platform9.puppet.net.pem ]];
do echo 'Waiting for cm${count.index} CSR request'; done
sudo /usr/local/bin/puppet cert sign --allow-dns-alt-names cm${count.index}.platform9.puppet.net
    EOF
    ]
  }
}
