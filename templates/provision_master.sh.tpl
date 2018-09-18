#!/bin/bash
yum install vim wget git -y
setenforce 0
mkdir -p /etc/puppetlabs/puppet
cp /home/centos/csr_attributes.yaml /etc/puppetlabs/puppet/csr_attributes.yaml
/usr/local/bin/puppet --version 2&> /dev/null
if [ $? -ne 0 ]; then
  echo "Puppet download url is ${url}${pe_ver}"
  wget --quiet --progress=bar:force --content-disposition "${url}${pe_ver}"
  if [ $? -ne 0 ]; then
    echo "Puppet failed to download"
    exit 2
  fi
  tar xzvf puppet-enterprise-*.tar* -C /root
  /root/puppet-enterprise-*/puppet-enterprise-installer -c /home/centos/custom-pe.conf -y
  rm -fr /root/puppet-enterprise-*
fi
/opt/puppetlabs/puppet/bin/puppet agent -t
echo "puppetlabs" | /opt/puppetlabs/bin/puppet-access login admin --lifetime 90d && \
echo "Deploying environment production from version control server" && \
/opt/puppetlabs/bin/puppet-code deploy production --wait && \
echo "Clearing environments cache" && \
/home/centos/puppet_scripts/update_environments.sh && \
echo "Clearing classifier cache" && \
/home/centos/puppet_scripts/update_classes.sh && \
/opt/puppetlabs/puppet/bin/puppet apply /home/centos/puppet_scripts/classification.pp && \
echo "Clearing environments cache" && \
/home/centos/puppet_scripts/update_environments.sh && \
echo "Clearing classifier cache" && \
/home/centos/puppet_scripts/update_classes.sh
/usr/local/bin/puppet agent -t
exit 0
