# Complete System Cleanup

To remove all installed Kubernetes components:

```bash
# Remove application
helm uninstall puhatak -n puhatak
kubectl delete namespace puhatak

# Remove Traefik
helm uninstall traefik -n traefik
kubectl delete namespace traefik

# Remove Gateway API CRDs
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Remove all GatewayClass (if any remain)
kubectl delete gatewayclass --all

# Remove remaining Gateway API CRDs
kubectl delete crd grpcroutes.gateway.networking.k8s.io

# Remove Traefik Helm repository
helm repo remove traefik

# Verify everything is removed
kubectl get gatewayclass
kubectl get crd | grep gateway
kubectl get namespace | grep traefik
helm repo list | grep traefik
```

After this, the system will return to the state before Gateway API components installation.
