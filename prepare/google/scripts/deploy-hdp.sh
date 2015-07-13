#!/usr/bin/env bash

#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>prep-hdp.out 2>&1

# Everything below will go to the file 'log.out':
el_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | cut -d. -f1)
case ${el_version} in
  "6")
    true
  ;;
  "7")
    sudo rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  ;;
esac

sudo yum -y install ipa-client openldap-clients git python-argparse epel-release patch
sudo service ntpd restart

git clone -b centos-7 https://github.com/seanorama/ambari-bootstrap
cd ambari-bootstrap
sudo install_ambari_server=true ./ambari-bootstrap.sh

sudo curl -sSL -o /etc/ambari-agent/conf/public-hostname-gcloud.sh https://github.com/GoogleCloudPlatform/bdutil/blob/master/platforms/hdp/resources/public-hostname-gcloud.sh
sudo sed -i.bak "/\[agent\]/ a public_hostname_script=\/etc\/ambari-agent\/conf\/public-hostname-gcloud.sh" /etc/ambari-agent/conf/ambari-agent.ini
sudo service ambari-agent restart

sleep 60

cat > /tmp/post-data.json <<-'EOF'
{ "Repositories" : {
    "base_url" : "http://public-repo-1.hortonworks.com/HDP-LABS/Projects/Dal-Preview/2.3.0.0-7/centos7",
    "mirrors_list" : null } }
EOF

curl -vSu admin:admin -H x-requested-by:sean http://localhost:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat7/repositories/HDP-2.3 -T /tmp/post-data.json

cat > /tmp/post-data.json <<-'EOF'
{ "Repositories" : {
    "base_url" : "http://public-repo-1.hortonworks.com/HDP-LABS/Projects/Dal-Preview/2.3.0.0-7/centos6",
    "mirrors_list" : null } }
EOF

curl -vSu admin:admin -H x-requested-by:sean http://localhost:8080/api/v1/stacks/HDP/versions/2.3/operating_systems/redhat6/repositories/HDP-2.3 -T /tmp/post-data.json

exit

cd ~/ambari-bootstrap/deploy
export ambari_services="AMBARI_METRICS KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE"
#export ambari_services="AMBARI_METRICS KNOX YARN ZOOKEEPER TEZ PIG SLIDER MAPREDUCE2 HIVE HDFS HBASE RANGER RANGER_KMS"
export cluster_name=$(hostname -s)
export host_count=skip
./deploy-recommended-cluster.bash
