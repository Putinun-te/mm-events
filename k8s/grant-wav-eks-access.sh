#!/bin/bash

# Grant Wav user access to EKS cluster
# Run this after creating the new cluster

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"
WAV_USER_ARN="arn:aws:iam::123456789012:user/Wav"

echo "🔐 Granting Wav user access to EKS cluster..."

# Create/update aws-auth ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: ${WAV_USER_ARN}
      username: wav
      groups:
        - system:masters
  mapRoles: |
    - rolearn: arn:aws:iam::123456789012:role/eksctl-concert-cluster-nodegroup-c-NodeInstanceRole-g4QyJADyFlIT
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

echo "✅ Wav granted cluster-admin access"
echo ""
echo "Wav can now run:"
echo "  aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
echo "  kubectl get nodes"
