# Kubernetes Deployment Guide

Deploy Cronicle on Kubernetes with full security hardening.

## Quick Start

```bash
# Deploy all resources
kubectl apply -f kubernetes.yaml

# Check deployment
kubectl -n cronicle get all

# Get admin password (after initialization)
kubectl -n cronicle exec -it deployment/cronicle -- cat /opt/cronicle/data/.admin_credentials

# Access the service (port-forward)
kubectl -n cronicle port-forward svc/cronicle 3012:3012
```

Access at: http://localhost:3012

## Configuration

### Update Secret Key

Before deploying, update the secret key:

```bash
# Generate random key
openssl rand -hex 32

# Update ConfigMap
kubectl -n cronicle edit configmap cronicle-config
```

Or create from file:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronicle-config
  namespace: cronicle
data:
  CRONICLE_base_app_url: "http://cronicle.example.com"
  CRONICLE_secret_key: "$(openssl rand -hex 32)"
  CRONICLE_server_hostname: "cronicle-k8s"
EOF
```

### Set Admin Password

```bash
# Create secret with custom password
kubectl create secret generic cronicle-admin \
  --from-literal=username=admin \
  --from-literal=password=YourSecurePassword123 \
  -n cronicle --dry-run=client -o yaml | kubectl apply -f -
```

## Storage

### Using Default StorageClass

The manifests use dynamic provisioning with default StorageClass:

```bash
# Check default StorageClass
kubectl get storageclass

# View PVCs
kubectl -n cronicle get pvc
```

### Using Specific StorageClass

Edit `kubernetes.yaml` and add to each PVC:

```yaml
spec:
  storageClassName: fast-ssd  # Your StorageClass name
  accessModes:
    - ReadWriteOnce
```

### Using Existing PersistentVolumes

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cronicle-data-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/cronicle
  claimRef:
    namespace: cronicle
    name: cronicle-data
```

## Ingress

### NGINX Ingress

Already configured in `kubernetes.yaml`:

```yaml
spec:
  ingressClassName: nginx
  rules:
  - host: cronicle.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
```

Update the hostname and apply.

### With TLS

```bash
# Create TLS secret
kubectl create secret tls cronicle-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n cronicle

# Update Ingress
kubectl -n cronicle patch ingress cronicle -p '
spec:
  tls:
  - hosts:
    - cronicle.example.com
    secretName: cronicle-tls
'
```

### Traefik Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cronicle
  namespace: cronicle
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  rules:
  - host: cronicle.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cronicle
            port:
              name: http
```

## Scaling

Cronicle supports multi-server mode:

```bash
# Scale to 3 replicas
kubectl -n cronicle scale deployment cronicle --replicas=3

# Configure master server (update ConfigMap)
kubectl -n cronicle edit configmap cronicle-config
# Add: CRONICLE_master_hostname: "cronicle-0.cronicle"
```

For multi-server, use StatefulSet instead of Deployment.

## Monitoring

### Health Checks

Built-in liveness and readiness probes:

```bash
# Check probe status
kubectl -n cronicle describe pod -l app=cronicle | grep -A 5 Liveness

# View events
kubectl -n cronicle get events --sort-by='.lastTimestamp'
```

### Prometheus Monitoring

Add ServiceMonitor for Prometheus:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cronicle
  namespace: cronicle
spec:
  selector:
    matchLabels:
      app: cronicle
  endpoints:
  - port: http
    interval: 30s
```

## Backup & Restore

### Backup

```bash
# Backup using kubectl cp
kubectl -n cronicle exec deployment/cronicle -- tar czf /tmp/backup.tar.gz /opt/cronicle/data
kubectl -n cronicle cp cronicle-pod:/tmp/backup.tar.gz ./cronicle-backup-$(date +%Y%m%d).tar.gz

# Or use Velero
velero backup create cronicle-backup --include-namespaces cronicle
```

### Restore

```bash
# Restore from backup
kubectl -n cronicle cp ./cronicle-backup.tar.gz cronicle-pod:/tmp/backup.tar.gz
kubectl -n cronicle exec deployment/cronicle -- tar xzf /tmp/backup.tar.gz -C /

# Or use Velero
velero restore create --from-backup cronicle-backup
```

## Security

### Pod Security Standards

Apply Pod Security Standards:

```bash
kubectl label namespace cronicle \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### Network Policies

Restrict network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cronicle-netpol
  namespace: cronicle
spec:
  podSelector:
    matchLabels:
      app: cronicle
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3012
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 587  # SMTP
```

## Troubleshooting

### Pod not starting

```bash
# Check logs
kubectl -n cronicle logs -l app=cronicle --tail=100

# Describe pod
kubectl -n cronicle describe pod -l app=cronicle

# Check events
kubectl -n cronicle get events --sort-by='.lastTimestamp'
```

### PVC not binding

```bash
# Check PVC status
kubectl -n cronicle get pvc

# Describe PVC
kubectl -n cronicle describe pvc cronicle-data

# Check available PVs
kubectl get pv
```

### Permission issues

```bash
# Check fsGroup
kubectl -n cronicle get pod -o jsonpath='{.items[0].spec.securityContext.fsGroup}'

# Fix volume permissions (if using hostPath)
sudo chown -R 1000:1000 /path/to/volume
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f kubernetes.yaml

# Delete namespace (removes everything)
kubectl delete namespace cronicle

# Delete PVs (if not auto-deleted)
kubectl delete pv -l app=cronicle
```

## Advanced: Helm Chart

For easier management, consider creating a Helm chart:

```bash
helm create cronicle-chart
# Move kubernetes.yaml resources into templates/
# Add values.yaml for configuration
helm install cronicle ./cronicle-chart -n cronicle --create-namespace
```

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
