#! /bin/bash

#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>prep-hdp.out 2>&1

pass="BadPassword_1"

sudo yum -y install *ipa-server bind bind-dyndb-ldap epel-release ntpd screen patch
sudo yum -y install haveged
sudo service haveged start; sudo chkconfig haveged on
sudo service ntpd restart

curl -sSL -O https://gist.githubusercontent.com/seanorama/fca566e558b6a459d362/raw/ae2c9ba08c771d91c41df2c97dda0eccfe137fc0/ipautil.el6.patch
sudo patch -b /usr/lib/python2.7/site-packages/ipapython/ipautil.py < ipautil.el6.patch

ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
sudo ipa-server-install --domain=hortonworks.local \
  --realm=HORTONWORKS.LOCAL --ds-password=${pass} \
  --master-password=${pass} --admin-password=${pass} \
  --zonemgr 'sroberts+workshop@hortonworks.com' \
  --hostname=$(hostname -f) --ip-address=$(ip)
  --setup-dns --forwarder=8.8.8.8 \
  --unattended --mkhomedir --no-ui-redirect

echo ${pass} | kinit admin
echo ${pass} | sudo kinit admin