# Kubernetes Deployment Strategies

This repository contains practical examples and guides for two popular Kubernetes deployment strategies: **Canary** and **Blue-Green**.

## 📁 Folder Structure

```
deployment-strategies/
├── canary/
│   ├── 01-deployment-v1.yaml
│   ├── 02-deployment-v2-canary.yaml
│   ├── 03-service.yaml
│   ├── 04-ingress.yaml
│   ├── 05-gateway-api-canary.yaml
│   └── CANARY-GUIDE.md
│
├── blue-green/
│   ├── 01-deployment-blue-v1.yaml
│   ├── 02-deployment-green-v2.yaml
│   ├── 03-service-production.yaml
│   ├── 04-service-blue.yaml
│   ├── 05-service-green.yaml
│   ├── 06-ingress.yaml
│   ├── 07-switch-to-green.yaml
│   ├── 08-switch-to-blue.yaml
│   └── BLUE-GREEN-GUIDE.md
│
└── README.md (this file)
```

---

## 🎯 Deployment Strategies Comparison

### Quick Comparison Table

| Aspect | Canary | Blue-Green |
|--------|--------|------------|
| **Traffic Switch** | Gradual (10% → 30% → 50% → 100%) | Instant (0% → 100%) |
| **Rollback Speed** | Fast (reduce traffic %) | Instant (switch back) |
| **Resource Usage** | Lower (~1.2x) | Higher (2x during deploy) |
| **Risk Level** | Very Low | Low |
| **Complexity** | Higher (traffic management) | Medium (simpler logic) |
| **Testing** | Test with real traffic gradually | Test fully before switch |
| **Best For** | Risk-averse, gradual rollouts | Quick deployments, instant rollback |

---

## 🐤 Canary Deployment

### What is it?

Gradually shift traffic from old version to new version, monitoring at each stage.

### Visual Flow:

```
v1: ████████████████████ 100%  →  Stage 1

v1: ██████████████████   90%   →  Stage 2
v2: ██                   10%

v1: ██████████████       70%   →  Stage 3
v2: ██████               30%

v1: ██████               30%   →  Stage 4
v2: ██████████████       70%

v2: ████████████████████ 100%  →  Complete
```

### When to Use:

✅ You want to minimize risk
✅ You have good monitoring and observability
✅ You can tolerate multiple versions running simultaneously
✅ You want to test with real production traffic

### Files:

Navigate to [`canary/`](./canary/) folder:
- `CANARY-GUIDE.md` - Complete guide with step-by-step instructions
- `01-deployment-v1.yaml` - Stable version (v1)
- `02-deployment-v2-canary.yaml` - Canary version (v2)
- `03-service.yaml` - Service routing to both versions
- `04-ingress.yaml` - Ingress configuration
- `05-gateway-api-canary.yaml` - Weight-based traffic splitting with Gateway API

### Quick Start:

```bash
cd canary/

# Deploy v1
kubectl apply -f 01-deployment-v1.yaml
kubectl apply -f 03-service.yaml
kubectl apply -f 04-ingress.yaml

# Deploy v2 canary (10% traffic)
kubectl apply -f 02-deployment-v2-canary.yaml

# Increase to 30% traffic
kubectl scale deployment app-v2-canary --replicas=2

# Complete migration (100% traffic)
kubectl scale deployment app-v1 --replicas=0
kubectl scale deployment app-v2-canary --replicas=5

# Or use Gateway API for precise control
kubectl apply -f 05-gateway-api-canary.yaml
```

---

## 🔵🟢 Blue-Green Deployment

### What is it?

Maintain two identical environments (Blue and Green). Deploy to inactive environment, test it, then switch traffic instantly.

### Visual Flow:

```
Stage 1: Blue is active
┌──────────┐        ┌──────────┐
│   BLUE   │ 100%   │  GREEN   │ 0%
│   (v1)   │ ◄────  │  (idle)  │
└──────────┘        └──────────┘

Stage 2: Deploy v2 to Green
┌──────────┐        ┌──────────┐
│   BLUE   │ 100%   │  GREEN   │ 0%
│   (v1)   │ ◄────  │   (v2)   │ ← Deploy & Test
└──────────┘        └──────────┘

Stage 3: Switch traffic (instant)
┌──────────┐        ┌──────────┐
│   BLUE   │ 0%     │  GREEN   │ 100%
│   (v1)   │        │   (v2)   │ ◄────
└──────────┘        └──────────┘
```

### When to Use:

✅ You need instant rollback capability
✅ You can afford 2x resources temporarily
✅ You want zero downtime deployments
✅ You prefer full testing before switching traffic
✅ You want all users on same version

### Files:

Navigate to [`blue-green/`](./blue-green/) folder:
- `BLUE-GREEN-GUIDE.md` - Complete guide with step-by-step instructions
- `01-deployment-blue-v1.yaml` - Blue environment (v1)
- `02-deployment-green-v2.yaml` - Green environment (v2)
- `03-service-production.yaml` - Production service (switchable)
- `04-service-blue.yaml` - Direct access to Blue
- `05-service-green.yaml` - Direct access to Green
- `06-ingress.yaml` - Ingress with 3 hosts (prod, blue, green)
- `07-switch-to-green.yaml` - Switch production to Green
- `08-switch-to-blue.yaml` - Rollback to Blue

### Quick Start:

```bash
cd blue-green/

# Deploy Blue (v1)
kubectl apply -f 01-deployment-blue-v1.yaml
kubectl apply -f 03-service-production.yaml
kubectl apply -f 04-service-blue.yaml
kubectl apply -f 06-ingress.yaml

# Deploy Green (v2)
kubectl apply -f 02-deployment-green-v2.yaml
kubectl apply -f 05-service-green.yaml

# Test Green
curl http://green.saudicloud.com

# Switch to Green (instant)
kubectl apply -f 07-switch-to-green.yaml

# Rollback to Blue (if needed)
kubectl apply -f 08-switch-to-blue.yaml
```

---

## 🐳 Docker Images Used

Both examples use these pre-built images:

- **v1**: `rahees9983/deployment-strategy-app:v1`
- **v2**: `rahees9983/deployment-strategy-app:v2`

These images respond with their version number, making it easy to verify which version is serving traffic.

---

## 🚀 Getting Started

### Prerequisites:

- Kubernetes cluster (ACK, EKS, GKE, or local)
- kubectl configured
- NGINX Ingress Controller installed
- (Optional) Gateway API for advanced Canary

### Choose Your Strategy:

1. **New to deployment strategies?** Start with **Blue-Green** (simpler)
2. **Want fine-grained control?** Use **Canary**
3. **High-risk deployment?** Use **Canary**
4. **Need instant rollback?** Use **Blue-Green**

### Test Environment:

Both strategies work with these hostnames (configure in your private DNS or hosts file):

**Canary:**
- `canary.saudicloud.com` - Main endpoint

**Blue-Green:**
- `bluegreen.saudicloud.com` - Production endpoint
- `blue.saudicloud.com` - Direct access to Blue
- `green.saudicloud.com` - Direct access to Green

---

## 📊 Decision Matrix

### Choose Canary if:

- [ ] You want to minimize risk to the absolute minimum
- [ ] You have excellent monitoring and observability
- [ ] You can spare 10-30% more resources
- [ ] Your deployment typically takes 1-2 hours
- [ ] You're okay with multiple versions running
- [ ] You want gradual confidence building

### Choose Blue-Green if:

- [ ] You need instant rollback capability
- [ ] You can afford 2x resources temporarily
- [ ] Your deployment window is short (< 15 minutes)
- [ ] You want all users on the same version
- [ ] You have comprehensive pre-production testing
- [ ] Database changes are backward compatible

### Choose Rolling Update (default) if:

- [ ] Your application is stateless
- [ ] You have minimal resources
- [ ] Deployment risk is low
- [ ] You're okay with slower rollback

---

## 🔍 Monitoring Your Deployment

### Key Metrics to Watch:

1. **Error Rate**: Should not increase
2. **Response Time**: Should remain stable (p50, p95, p99)
3. **CPU/Memory**: Should not spike
4. **Request Count**: Should match traffic expectations
5. **Pod Health**: All pods should be Ready

### Monitoring Commands:

```bash
# Watch pods
watch kubectl get pods -l app=myapp

# Monitor logs
kubectl logs -l version=v2 -f

# Check resource usage
kubectl top pods -l app=myapp

# Traffic distribution
for i in {1..50}; do curl -s http://your-app.com; done | sort | uniq -c
```

---

## 🛠️ Common Commands

### Both Strategies:

```bash
# Check deployment status
kubectl get deployments
kubectl rollout status deployment/<name>

# View pods
kubectl get pods -l app=myapp
kubectl describe pod <pod-name>

# Check services
kubectl get svc
kubectl get endpoints <service-name>

# View logs
kubectl logs -l app=myapp --tail=50
kubectl logs -f <pod-name>

# Check resource usage
kubectl top pods
kubectl top nodes

# Delete all resources
kubectl delete -f .
```

### Canary-Specific:

```bash
# Scale canary
kubectl scale deployment app-v2-canary --replicas=2

# Adjust Gateway API weights
kubectl edit httproute myapp-canary-route
```

### Blue-Green-Specific:

```bash
# Check active environment
kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}'

# Switch to Green
kubectl apply -f 07-switch-to-green.yaml

# Rollback to Blue
kubectl apply -f 08-switch-to-blue.yaml
```

---

## 📚 Additional Resources

### Official Documentation:

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)

### Tools for Advanced Deployments:

- **Flagger**: Automated canary deployments
- **Argo Rollouts**: Progressive delivery controller
- **Spinnaker**: Multi-cloud CD platform
- **Jenkins X**: GitOps-based CD for Kubernetes

---

## 🎓 Learning Path

1. **Start Here**: Read this README
2. **Understand Concepts**: Read both guide files
3. **Try Blue-Green First**: Simpler to understand
4. **Then Try Canary**: More advanced but powerful
5. **Experiment**: Mix strategies, try Gateway API
6. **Automate**: Create scripts for your deployments

---

## 🤝 Best Practices

1. **Always Test First**: Never deploy directly to production
2. **Monitor Continuously**: Watch metrics during deployment
3. **Have Rollback Plan**: Know how to revert quickly
4. **Document Everything**: Keep deployment logs
5. **Automate**: Use CI/CD pipelines
6. **Practice**: Run through deployments in staging
7. **Communicate**: Keep team informed during deployments

---

## 💡 Pro Tips

- **Canary**: Start with 5-10% traffic, increase slowly
- **Blue-Green**: Test Green thoroughly before switching
- **Both**: Keep monitoring dashboards open
- **Both**: Have team member ready during deployment
- **Both**: Schedule deployments during low-traffic periods
- **Database**: Plan schema changes carefully
- **Sessions**: Consider sticky sessions or session migration

---

## 🐛 Troubleshooting

### Pods Not Starting:

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### Service Not Routing Traffic:

```bash
kubectl get endpoints <service-name>
kubectl describe svc <service-name>
kubectl get pods -l <selector> --show-labels
```

### Ingress Not Working:

```bash
kubectl describe ingress <ingress-name>
kubectl logs -n kube-system -l app=nginx-ingress
```

---

## 📝 Summary

This repository provides complete, production-ready examples of:

✅ **Canary Deployment** - Gradual traffic shifting
✅ **Blue-Green Deployment** - Instant traffic switching
✅ **Gateway API** - Modern traffic management
✅ **Multiple approaches** - Pod-based and weight-based
✅ **Comprehensive guides** - Step-by-step instructions
✅ **Real examples** - Using your actual Docker images

Choose the strategy that fits your needs and start deploying with confidence!

---

## 🚦 Quick Reference

| I want to... | Use Strategy | Go to |
|--------------|-------------|-------|
| Minimize risk with gradual rollout | Canary | [`canary/`](./canary/) |
| Deploy quickly with instant rollback | Blue-Green | [`blue-green/`](./blue-green/) |
| Fine-grained traffic control | Canary + Gateway API | [`canary/05-gateway-api-canary.yaml`](./canary/05-gateway-api-canary.yaml) |
| Test new version before going live | Blue-Green | [`blue-green/`](./blue-green/) |
| Learn deployment strategies | Start with Blue-Green, then Canary | Both guides |

---

Happy Deploying! 🚀
