# K3s and Gateway Controller Setup

## Install Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

(Linux only) Remove already installed Traefik (it's outdated):

```bash
kubectl -n kube-system delete helmchart traefik traefik-crd
kubectl -n kube-system delete deployment traefik
kubectl -n kube-system delete service traefik
```

## Install Traefik 3.0+

### For Docker Desktop (macOS)

First check and remove NGINX Ingress Controller (if installed):
```bash
# Check if NGINX is installed
kubectl get svc -A | grep nginx

# If installed, remove it
kubectl delete -n ingress-nginx deployment ingress-nginx-controller
kubectl delete -n ingress-nginx service ingress-nginx-controller ingress-nginx-controller-admission
kubectl delete namespace ingress-nginx
```

Install/update Traefik:
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set image.tag=v3.0 \
  --set providers.kubernetesGateway.enabled=true \
  --set experimental.kubernetesGateway.enabled=true \
  --set service.type=LoadBalancer \
  --set gateway.enabled=true \
  --set gatewayClass.enabled=true

# Verify that Traefik got localhost address
kubectl get svc traefik -n traefik
```

### For k3s (Linux)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
    --namespace traefik --create-namespace \
    --set image.tag=v3.0 \
    --set providers.kubernetesGateway.enabled=true \
    --set experimental.kubernetesGateway.enabled=true \
    --set service.type=LoadBalancer \
    --set gateway.enabled=true \
    --set gatewayClass.enabled=true
```
