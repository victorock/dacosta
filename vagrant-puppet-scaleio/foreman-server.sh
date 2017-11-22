
#!/bin/bash

echo 'Configuring /etc/hosts'

echo '10.0.1.9 master.scaleio.local' >> /etc/hosts
hostnamectl set-hostname master.scaleio.local

echo 'Installing Foreman requirements.'
yum-config-manager --enable rhel-7-server-optional-rpms rhel-server-rhscl-7-rpms
yum --nogpgcheck -y install http://yum.theforeman.org/releases/latest/el7/x86_64/rhscl-ruby193-epel-7-x86_64-1-2.noarch.rpm
yum --nogpgcheck -y install http://yum.theforeman.org/releases/latest/el7/x86_64/rhscl-v8314-epel-7-x86_64-1-2.noarch.rpm
yum --nogpgcheck -y install epel-release-7-5 rhscl-ruby193-epel-7-x86_64
yum --nogpgcheck -y install postgresql postgresql-server postgresql-devel git

echo 'Installing Foreman.'
yum --nogpgcheck -y install http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum --nogpgcheck -y install http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm
yum --nogpgcheck -y install foreman foreman-installer foreman-cli foreman-postgresql nfs-utils
foreman-installer \
  --foreman-servername="master.scaleio.local" \
  --reset-foreman-db \
  --enable-puppet \
  --foreman-ssl=true \
  --foreman-admin-password="Scaleio123" \
  --foreman-environment="production" \
  --enable-foreman-plugin-salt \
  --enable-foreman-compute-vmware \
  --enable-foreman-compute-ec2 \
  --enable-foreman-compute-openstack \
  --enable-foreman-plugin-docker \
  --enable-foreman-plugin-chef \
  --enable-foreman-plugin-puppetdb \
  --foreman-configure-epel-repo \
  --foreman-configure-scl-repo

echo 'Installing Puppet Modules.'
# Install some optional puppet modules on Foreman server to get started...
puppet module install puppetlabs-ntp
puppet module install puppetlabs-git
puppet module install --ignore-dependencies puppetlabs-docker_platform
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-firewall
puppet module install puppetlabs-java
puppet module install dalen-dnsquery
puppet module install herculesteam/augeasproviders_ssh

# Using latest my own version for now
# pull request under approval
#puppet module install emccode-scaleio

echo 'Configuring Puppet'
echo '*.scaleio.local' > /etc/puppet/autosign.conf
puppet config set --section master certname master.scaleio.local
puppet config set --section main pluginsync true
puppet config set --section main parser future
puppet config set --section agent splay true
puppet config set --section agent splaylimit 120
puppet config set --section agent runinterval 120

puppet resource service iptables ensure=stopped enable=false
puppet resource service firewalld ensure=stopped enable=false
puppet resource service rpcbind ensure=running enable=true
puppet resource service nfs-server ensure=running enable=true

foreman-rake reports:expire days=7
foreman-rake puppet:import:puppet_classes
sudo -u puppet /etc/puppet/node.rb --push-facts

echo 'Downloading Scaleio Package'
yum --nogpgcheck -y install unzip
echo 'Performing a ~250MB download of ScaleIO RPMs'
wget -nv ftp://ftp.emc.com/Downloads/ScaleIO/ScaleIO_RHEL6_Download.zip -O /tmp/ScaleIO_RHEL6_Download.zip

echo 'Creating Scaleio Local Repository'
unzip /tmp/ScaleIO_RHEL6_Download.zip -d /tmp/scaleio
mkdir -p /tmp/scaleio /mnt/scaleio/RedHat
cp -a /tmp/scaleio/*RHEL7*/* /mnt/scaleio/RedHat
cp -a /tmp/scaleio/*/*noarch* /mnt/scaleio/RedHat

echo "[scaleio-repo]" >> /mnt/scaleio/local-scaleio.repo
echo "name = Scaleio-Repo" >> /mnt/scaleio/local-scaleio.repo
echo "baseurl = file:///mnt/scaleio" >> /mnt/scaleio/local-scaleio.repo
echo "enabled=1" >> /mnt/scaleio/local-scaleio.repo
echo "gpgcheck=0" >> /mnt/scaleio/local-scaleio.repo
echo "protect=1" >> /mnt/scaleio/local-scaleio.repo

yum --nogpgcheck -y install createrepo
createrepo /mnt/scaleio

echo "/mnt/scaleio 10.0.0.0/16(ro,async,insecure)" >>/etc/exports
echo "/mnt/scaleio 192.168.0.0/16(ro,async,insecure)" >>/etc/exports
exportfs -ra

echo 'Installing victorck/puppet-scaleio'
cd /etc/puppet/modules/
git clone https://github.com/victorock/puppet-scaleio
mv puppet-scaleio scaleio
chown puppet:root scaleio

echo 'Updating system.'
yum --nogpgcheck -y update
