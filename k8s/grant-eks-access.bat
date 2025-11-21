@echo off
REM Grant root account access to EKS cluster
REM Run this as user Wav who created the cluster

set CLUSTER_NAME=concert-cluster
set REGION=ap-southeast-1
set ROOT_ACCOUNT=123456789012

echo Granting root account access to EKS cluster...
echo.

REM Get current aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml

REM Create updated aws-auth with root access
(
echo apiVersion: v1
echo kind: ConfigMap
echo metadata:
echo   name: aws-auth
echo   namespace: kube-system
echo data:
echo   mapUsers: ^|
echo     - userarn: arn:aws:iam::%ROOT_ACCOUNT%:root
echo       username: root-admin
echo       groups:
echo         - system:masters
) > aws-auth-patch.yaml

REM Apply the patch
kubectl apply -f aws-auth-patch.yaml

echo.
echo Root account granted cluster-admin access
echo.
echo Now root user can run:
echo   aws eks update-kubeconfig --region %REGION% --name %CLUSTER_NAME%
echo   kubectl get nodes
