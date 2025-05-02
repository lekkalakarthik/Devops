#!/bin/bash

set -e

LOG_FILE="/var/log/k8s_install.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "[INFO] Kubernetes 1.29 installation starting..."
sleep 2

# Function to pause and wait
pause() {
  echo ""
  read -p "Press [Enter] to continue..."
}

# Ask if user wants to run yum update
read -p "[QUESTION] Do you want to update all system packages with 'yum update -y'? (y/n): " update_choice
if [[ "$update_choice" == "y" ]]; then
  echo "[INFO] Running yum update..."
  yum clean all
  yum update -y
  echo "[INFO] Update complete. Reboot is recommended. Rebooting in 10 seconds..."
  sleep 10
  reboot
  exit 0
else
  echo "[INFO] Skipping system update."
fi

echo "[STEP 1] Disable SELinux and Swap"
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
sleep 2

echo "[STEP 2] Enable br_netfilter and sysctl settings"
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
EOF
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables  = 1
net.bridge.bridge-nf-call-iptables   = 1
net.ipv4.ip_forward                  = 1
EOF
sysctl --system
sleep 2

echo "[STEP 3] Install containerd"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd
sleep 2

echo "[STEP 4] Add Kubernetes 1.29 repository"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
sleep 2

echo "[STEP 5] Install kubeadm, kubelet, and kubectl"
yum install -y kubelet kubeadm kubectl
systemctl enable --now kubelet
sleep 2

echo "[STEP 6] Initialization (master only)"
read -p "Is this the master node? (y/n): " is_master
if [[ "$is_master" == "y" ]]; then
  echo "[INFO] Initializing cluster with kubeadm..."
  kubeadm init --pod-network-cidr=192.168.0.0/16

  echo "[INFO] Setting up kubectl for user: $USER"
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  echo "[INFO] Installing Calico network plugin"
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

  echo "[INFO] Master node initialized!"
else
  echo "[INFO] Worker node ready. Use kubeadm join command from master to join this node."
fi

echo "[✅ SUCCESS] Kubernetes 1.29 setup completed."
pause
