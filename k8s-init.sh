#k8s-init.sh

#!/usr/bin/env bash
#-*- coding:utf-8 -*-
# Modify Author: kun zheng <shendaoshu@gmail.com>
# Modify Date:   2021-08-04 16:00
# Github URL:    https://github.com/shendaoshu
# Version:       1.0

# Add host domain name.
cat >> /etc/hosts << EOF
192.168.188.245 k8s-master01 m1
192.168.188.246 k8s-master02 m2
192.168.188.247 k8s-master03 m3
192.168.188.248 k8s-node01   w1
192.168.188.249 k8s-node02   w2
192.168.188.250 k8s-node03   w3
192.168.188.101 k8s-ng01     n1
192.168.188.102 k8s-ng02     n2
EOF

# Disable the SELinux.
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Disable the Swap.
sed -ri 's/.*swap.*/#&/' /etc/fstab

# Turn off and disable the firewalld.
systemctl stop firewalld
systemctl disable firewalld

# Modify related kernel parameters.
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Install rpm.
yum install -y vim ntpdate ntp conntrack git openssl openssl-devel curl bash-completion net-tools.x86_64 podman httpd httpd-tools ipvsadm ipset jq iptables sysstat libseccomp gcc gcc-c++ make 
ntpdate ntp.aliyun.com

# Install Docker.
yum install -y wget
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum -y install docker-ce

systemctl start docker
systemctl enable docker

mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://u2nhke40.mirror.aliyuncs.com"]
}
EOF

systemctl daemon-reload
systemctl restart docker

# Update kernel.
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum --enablerepo="elrepo-kernel" install -y kernel-ml.x86_64 
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg
#rpm -qa|grep kernel
yum update -y

# Reboot the machine.
reboot
