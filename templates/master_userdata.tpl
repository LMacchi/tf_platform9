#cloud-config
packages:
  - vim
  - wget
  - git
runcmd:
  - export HOME=/root
  - setenforce 0
  - mkdir -p /etc/puppetlabs/puppet
  - cp /home/centos/csr_attributes.yaml /etc/puppetlabs/puppet/csr_attributes.yaml
  - chmod +x /home/centos/puppet_scripts/*.sh
  - echo "Puppet download url is ${url}"
  - wget --quiet --progress=bar:force --content-disposition "${url}"
  - tar xzvf puppet-enterprise-*.tar* -C /root
  - /root/puppet-enterprise-*/puppet-enterprise-installer -c /home/centos/custom-pe.conf -y
  - rm -fr /root/puppet-enterprise-*
  - /opt/puppetlabs/puppet/bin/puppet agent -t
  - echo "puppetlabs" | /opt/puppetlabs/bin/puppet-access login admin --lifetime 90d
  - echo "Deploying puppet code from version control server"
  - /home/centos/puppet_scripts/deploy_code.sh
  - echo "Clearing environments cache"
  - /home/centos/puppet_scripts/update_environments.sh
  - echo "Clearing classifier cache"
  - /home/centos/puppet_scripts/update_classes.sh
  - /opt/puppetlabs/puppet/bin/puppet apply /home/centos/puppet_scripts/classification.pp
  - echo "Clearing environments cache"
  - /home/centos/puppet_scripts/update_environments.sh
  - echo "Clearing classifier cache"
  - /home/centos/puppet_scripts/update_classes.sh
  - /usr/local/bin/puppet agent -t
