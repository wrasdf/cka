#!/usr/bin/env bash

/usr/bin/kubeadm join \
  --token $(cat /etc/kubernetes/token) \
  --discovery-token-ca-cert-hash sha256:$(cat /etc/kubernetes/pki/ca.sha256) \
  --ignore-preflight-errors=all \
  api.internal.${CLUSTER_NAME}.${CLUSTER_DOMAIN}:443

systemctl enable kubelet
systemctl start kubelet

# assert services are running
systemctl is-active docker
systemctl is-active kubelet

kubectl --kubeconfig=/etc/kubernetes/kubelet.conf \
  label node "$(hostname)" node-role.kubernetes.io/node="" \
  --overwrite=true
