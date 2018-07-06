#cloud-config
hostname: "${hostname}"
fqdn: "${fqdn}"
manage_etc_hosts: true
packages:
  - vim
  - wget
  - git
runcmd:
  - export HOME=/root
  - setenforce 0
  - curl -s -k https://master.platform9.puppet.net:8140/packages/current/install.bash | bash -s extension_requests:pp_role=agent custom_attributes:challengePassword=S3cr3tP@ssw0rd!
  - /usr/local/bin/puppet agent -t
