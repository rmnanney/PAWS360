# PAWS360 Production Deployment Summary

**Deployment Date:** December 2, 2025  
**Status:** ✅ LIVE and OPERATIONAL  
**URL:** https://paws360.ryannanney.com

---

## Deployment Architecture

### Infrastructure
- **Platform:** K3s Kubernetes Cluster (v1.31.5+k3s1)
- **Nodes:** 
  - `dell-r640-01` (control-plane)
  - `dell-r640-02` (worker)
- **Ingress Controller:** Traefik
- **External IP:** 192.168.0.201 (via pfSense NAT: 184.58.181.145)
- **TLS:** Let's Encrypt (cert-manager, letsencrypt-prod issuer)

### Application Components

#### PostgreSQL Database
- **Image:** postgres:15-alpine
- **Type:** StatefulSet (1 replica)
- **Storage:** 10Gi PersistentVolume
- **Database:** `paws360_prod`
- **Configuration:** TCP-only (Unix sockets disabled for K8s compatibility)
- **Security Context:** runAsUser/Group/fsGroup: 70

#### Redis Cache
- **Image:** redis:7-alpine
- **Type:** StatefulSet (1 replica)
- **Storage:** 5Gi PersistentVolume
- **Authentication:** Password-protected

#### Backend (Spring Boot)
- **Image:** ghcr.io/rmnanney/paws360:backend-prod-38c17e91
- **Type:** Deployment (2 replicas)
- **Resources:** 512Mi-2Gi RAM, 500m-2000m CPU
- **Java Version:** 21
- **Startup Time:** ~12.4 seconds
- **Health Checks:** Liveness, Readiness, Startup probes configured
- **Security:** AppArmor unconfined profile

#### Frontend (Next.js)
- **Image:** ghcr.io/rmnanney/paws360:frontend-prod-38c17e91
- **Type:** Deployment (2 replicas)
- **Server:** `npx serve@latest` (static file server)
- **Output Mode:** Static export
- **Resources:** 128Mi-512Mi RAM, 100m-500m CPU
- **Security:** Runs as root (required for npx serve)

---

## Network Configuration

### Services
```
paws360-backend    ClusterIP   10.43.18.110    8080/TCP
paws360-frontend   ClusterIP   10.43.136.238   3000/TCP
paws360-postgres   ClusterIP   None            5432/TCP (Headless)
paws360-redis      ClusterIP   None            6379/TCP (Headless)
```

### Ingress Routing
- **Class:** traefik
- **Host:** paws360.ryannanney.com
- **Routes:**
  - `/api/*` → Backend (with /api prefix stripping via middleware)
  - `/actuator/*` → Backend (direct passthrough)
  - `/*` → Frontend

### Middleware
- **strip-api-prefix:** Removes `/api` prefix before routing to backend

---

## Security Configuration

### Secrets (Namespace: paws360-secret)
```
POSTGRES_PASSWORD: P4ws360_Pr0d_DB_2025!
REDIS_PASSWORD: P4ws360_R3dis_C4che_2025!
JWT_SECRET: P4ws360-JWT-S3cr3t-Pr0ducti0n-2025-K3y-M1n32Ch4rs!
```

### TLS Certificate
- **Issuer:** letsencrypt-prod
- **Status:** READY ✅
- **Secret:** paws360-tls

---

## Deployment Validation

### Pod Status
```
NAME                               READY   STATUS    NODE
paws360-backend-767759d7c7-5ks2n   1/1     Running   dell-r640-01
paws360-backend-767759d7c7-928kt   1/1     Running   dell-r640-02
paws360-frontend-f9f76d8c-2gkbt    1/1     Running   dell-r640-01
paws360-frontend-f9f76d8c-4wp8x    1/1     Running   dell-r640-02
paws360-postgres-0                 1/1     Running   dell-r640-01
paws360-redis-0                    1/1     Running   dell-r640-01
```

### External Access Tests
- ✅ Frontend: https://paws360.ryannanney.com/ → HTTP 200
- ✅ Backend Health: https://paws360.ryannanney.com/api/actuator/health → UP
- ✅ Actuator: https://paws360.ryannanney.com/actuator/health → UP
- ✅ TLS: Valid Let's Encrypt certificate

### Backend Health Details
```json
{
  "status": "UP",
  "components": {
    "db": {"status": "UP", "details": {"database": "PostgreSQL"}},
    "diskSpace": {"status": "UP"},
    "livenessState": {"status": "UP"},
    "readinessState": {"status": "UP"},
    "ping": {"status": "UP"},
    "ssl": {"status": "UP"}
  }
}
```

---

## Manifest Files

All Kubernetes manifests are stored in:
```
/home/ryan/repos/infrastructure/k8s-manifests/paws360/
```

Files:
- `namespace.yaml` - Namespace definition
- `configmap.yaml` - Application configuration
- `postgres-statefulset.yaml` - PostgreSQL database
- `redis-statefulset.yaml` - Redis cache
- `backend-deployment.yaml` - Spring Boot backend
- `frontend-deployment.yaml` - Next.js frontend
- `service.yaml` - ClusterIP services
- `ingress.yaml` - Traefik ingress with TLS
- `middleware.yaml` - Traefik middleware for path rewriting
- `README.md` - Deployment documentation

---

## Known Issues & Resolutions

### Issue 1: PostgreSQL Unix Socket Permissions
**Problem:** PostgreSQL couldn't create Unix sockets in K8s  
**Solution:** Disabled Unix sockets with `unix_socket_directories=` argument, use TCP connections only

### Issue 2: Next.js Static Export
**Problem:** `next start` incompatible with `output: export`  
**Solution:** Use `npx serve@latest out -l 3000` for serving static files

### Issue 3: GHCR Authentication
**Problem:** 401 Unauthorized pulling from ghcr.io  
**Solution:** Imported images directly to K3s nodes via `k3s ctr images import`

### Issue 4: Ingress Class Mismatch
**Problem:** Ingress configured for nginx, but cluster uses Traefik  
**Solution:** Updated `ingressClassName: traefik` and used Traefik-specific annotations

### Issue 5: API Path Routing
**Problem:** Backend doesn't use `/api` prefix internally  
**Solution:** Created Traefik middleware to strip `/api` prefix before routing

---

## Operational Commands

### Check Deployment Status
```bash
kubectl get all -n paws360
```

### View Logs
```bash
kubectl logs -n paws360 -l app=paws360-backend --tail=100
kubectl logs -n paws360 -l app=paws360-frontend --tail=100
```

### Database Access
```bash
kubectl exec -it paws360-postgres-0 -n paws360 -- psql -U paws360 -d paws360_prod
```

### Backend Health Check
```bash
kubectl exec -n paws360 paws360-backend-<pod-name> -- curl http://localhost:8080/actuator/health
```

### Scale Deployments
```bash
kubectl scale deployment paws360-backend -n paws360 --replicas=3
kubectl scale deployment paws360-frontend -n paws360 --replicas=3
```

---

## Future Improvements

1. **Monitoring:** Add Prometheus metrics collection
2. **Logging:** Integrate with centralized logging (ELK stack)
3. **Backup:** Automated PostgreSQL backup to persistent storage
4. **Security:** Run frontend as non-root user (requires serve alternatives)
5. **Scaling:** Configure HorizontalPodAutoscaler based on CPU/memory
6. **Database:** Consider PostgreSQL HA setup (replication)
7. **Redis:** Redis cluster mode for HA

---

## Deployment Timeline

1. Created Kubernetes manifests in infrastructure repository
2. Resolved PostgreSQL Unix socket permission issues (8+ iterations)
3. Deployed PostgreSQL StatefulSet with TCP-only configuration
4. Deployed Redis StatefulSet with password authentication
5. Imported Docker images to K3s nodes (GHCR auth workaround)
6. Deployed backend (2 replicas) - successful database connectivity
7. Resolved Next.js static export issue (switched to serve command)
8. Deployed frontend (2 replicas) with static file server
9. Created Traefik ingress with TLS
10. Configured middleware for API path rewriting
11. Verified external access via https://paws360.ryannanney.com

**Total Deployment Time:** ~2 hours (including troubleshooting)

---

## Contact & Support

**Repository:** /home/ryan/repos/PAWS360  
**Infrastructure:** /home/ryan/repos/infrastructure  
**Deployment Date:** December 2, 2025  
**Deployed By:** GitHub Copilot (Automated Deployment Agent)
