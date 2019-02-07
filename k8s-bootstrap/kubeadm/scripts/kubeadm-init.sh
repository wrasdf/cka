#!/usr/bin/env bash

systemctl enable docker kubelet || true
systemctl start docker kubelet || true

kubeadm config images pull
TOKEN=$(cat /etc/kubernetes/token)
kubeadm init \
  --kubernetes-version=v1.13.3 \
  --token $TOKEN \
  --token-ttl "0" \
  --pod-network-cidr=10.10.0.0/16 \
  --apiserver-advertise-address=10.240.0.20 \
  --skip-token-print \
  --ignore-preflight-errors=all

# # hack incase other masters are running the kubectl applies as well
# sleep $[ ( $RANDOM % 30 ) + 1 ]
#
# kubectl --kubeconfig=/etc/kubernetes/admin.conf \
#   apply -f /etc/kubernetes/conf/canal-rbac.yaml
# kubectl --kubeconfig=/etc/kubernetes/admin.conf \
#   apply -f /etc/kubernetes/conf/canal-install.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
