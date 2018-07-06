#cloud-config
hostname: "${hostname}"
fqdn: "${hostname}.${domain}"
manage_etc_hosts: true
packages:
  - vim
  - wget
  - git
  - nc
runcmd:
  - export HOME=/root
  - setenforce 0
  - while ! nc -z master.${domain} 8140; do echo "Waiting for Puppet master to be ready"; sleep 5; done
  - curl -s -k https://master.${domain}:8140/packages/current/install.bash | bash -s main:dns_alt_names=puppet,puppet.${domain},lb,lb.${domain} extension_requests:pp_role=${role} custom_attributes:challengePassword=${autosign_pwd}
  - /usr/local/bin/puppet agent -t
