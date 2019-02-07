#!/usr/bin/env bash
systemctl enable docker
systemctl start docker

/usr/bin/kubeadm join \
  --token $(cat /etc/kubernetes/token) \
  --discovery-token-ca-cert-hash sha256:$(cat /etc/kubernetes/pki/ca.sha256) \
  --ignore-preflight-errors=all

kubectl label node "$(hostname)" node-role.kubernetes.io/node=""

systemctl enable kubelet
systemctl start kubelet

# assert services are running
systemctl is-active docker
systemctl is-active kubelet
