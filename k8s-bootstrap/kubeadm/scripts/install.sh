#!/usr/bin/env bash

set -euo pipefail

# update hosts
echo "10.240.0.20 master
10.240.0.21 node1
10.240.0.22 node2
" >> /etc/hosts

# disable firewall
systemctl stop firewalld
systemctl disable firewalld

# install dependencies
yum -y update
yum -y install gcc openssl openssl-devel bzip2-devel libffi-devel yum-utils socat ebtables rsyslog groupinstall development curl
yum -y install https://centos7.iuscommunity.org/ius-release.rpm
yum -y install python36u python36u-libs python36u-devel python36u-pip

# install docker & docker-compose
yum install -y device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce epel-release
pip3.6 install docker-compose

# install gomplate
GOMPLATE_VERSION=3.1.0
curl -L -o /usr/bin/gomplate "https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64"
chmod +x /usr/bin/gomplate

# install kubeadm kubelet kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# install etcd
ETCD_VERSION=3.2.18
curl -L "https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz" | tar xz --no-same-owner
mv etcd-v"${ETCD_VERSION}"-linux-amd64/etcdctl /usr/bin/
rm -rf etcd-v"${ETCD_VERSION}"-linux-amd64

yum clean all
rm -rf /var/cache/yum

# create dirs
mkdir -p /etc/etcd
mkdir -p /etc/systemd/system
mkdir -p /vagrant/global/{scripts,services,conf}
mkdir -p /vagrant/etcd/{scripts,services,conf}
mkdir -p /vagrant/kubernetes/{scripts,services,conf}
mkdir -p /opt/kubernetes
mkdir -p /etc/kubernetes/conf
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/cni
mkdir -p /opt/cni/bin
chown -R vagrant /vagrant/global /vagrant/etcd /vagrant/kubernetes

# copy files
mv /vagrant/services/* /etc/systemd/system/

chown root:root /vagrant/scripts/*
chmod +x /vagrant/scripts/*
mv /vagrant/conf/k8s-sysctl.conf /etc/sysctl.d/k8s.conf
mv /vagrant/conf/* /etc/kubernetes/conf/

modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

# turn off swap
swapoff -a

# Write default bootstrap token
echo abcdef.hijklmnopqrstuvx > /etc/kubernetes/token
