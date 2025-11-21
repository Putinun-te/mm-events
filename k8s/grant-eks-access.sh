#!/bin/bash

# Grant root account access to EKS cluster
# Run this as user Wav who created the cluster

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"
ROOT_ACCOUNT="123456789012"

echo "🔐 Granting root account access to EKS cluster..."

# Get current aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml > /tmp/aws-auth-backup.yaml

# Create updated aws-auth with root access
cat > /tmp/aws-auth-patch.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ROOT_ACCOUNT}:root
      username: root-admin
      groups:
        - system:masters
EOF

# Apply the patch
kubectl apply -f /tmp/aws-auth-patch.yaml

echo "✅ Root account granted cluster-admin access"
echo ""
echo "Now root user can run:"
echo "  aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
echo "  kubectl get nodes"
