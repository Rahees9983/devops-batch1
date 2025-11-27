# Deployment Strategies Cheat Sheet

Quick reference for Canary and Blue-Green deployments.

---

## 🐤 Canary Deployment

### Quick Facts
- **Time:** 2-4 hours
- **Risk:** Very Low (5-30% users affected)
- **Rollback:** < 10 seconds
- **Resources:** 110-120%

### One-Liner
> Gradually shift traffic: 10% → 30% → 50% → 100%

### Quick Deploy
```bash
# 1. Deploy v1
kubectl apply -f canary/01-deployment-v1.yaml
kubectl apply -f canary/03-service.yaml

# 2. Deploy v2 canary (10% traffic)
kubectl apply -f canary/02-deployment-v2-canary.yaml

# 3. Monitor & increase
kubectl scale deployment app-v2-canary --replicas=2  # 30%
kubectl scale deployment app-v2-canary --replicas=3  # 50%

# 4. Complete
kubectl scale deployment app-v1 --replicas=0
kubectl scale deployment app-v2-canary --replicas=5
```

### Quick Rollback
```bash
kubectl scale deployment app-v2-canary --replicas=0
```

### With Gateway API (Precise Control)
```yaml
backendRefs:
  - name: v1-service
    weight: 90  # Adjust weights
  - name: v2-service
    weight: 10
```

---

## 🔵🟢 Blue-Green Deployment

### Quick Facts
- **Time:** 30-60 minutes
- **Risk:** Low (instant switch affects all)
- **Rollback:** < 5 seconds
- **Resources:** 200% (during deploy)

### One-Liner
> Deploy to Green, test it, switch instantly, rollback if needed

### Quick Deploy
```bash
# 1. Deploy Blue (v1)
kubectl apply -f blue-green/01-deployment-blue-v1.yaml
kubectl apply -f blue-green/03-service-production.yaml
kubectl apply -f blue-green/04-service-blue.yaml

# 2. Deploy Green (v2)
kubectl apply -f blue-green/02-deployment-green-v2.yaml
kubectl apply -f blue-green/05-service-green.yaml

# 3. Test Green
curl http://green.saudicloud.com

# 4. Switch to Green
kubectl apply -f blue-green/07-switch-to-green.yaml
```

### Quick Rollback
```bash
kubectl apply -f blue-green/08-switch-to-blue.yaml
```

### Manual Switch
```bash
# To Green
kubectl patch svc myapp-production -p '{"spec":{"selector":{"environment":"green"}}}'

# To Blue
kubectl patch svc myapp-production -p '{"spec":{"selector":{"environment":"blue"}}}'
```

---

## 🚀 Quick Commands

### Check What's Running
```bash
# Pods
kubectl get pods -l app=myapp

# By version
kubectl get pods -l version=v1
kubectl get pods -l version=v2

# By environment
kubectl get pods -l environment=blue
kubectl get pods -l environment=green

# Services
kubectl get svc
kubectl get endpoints myapp-production
```

### Monitor Deployment
```bash
# Watch pods
watch kubectl get pods -l app=myapp

# Stream logs (canary)
kubectl logs -l version=v2 -f

# Stream logs (blue-green)
kubectl logs -l environment=green -f

# Resource usage
kubectl top pods -l app=myapp
```

### Test Traffic Distribution
```bash
# Test 50 times
for i in {1..50}; do
  curl -s http://your-app.com | grep version
done | sort | uniq -c

# Test with load
ab -n 1000 -c 10 http://your-app.com/
```

### Check Active Version (Blue-Green)
```bash
# Quick check
kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}'

# Detailed
kubectl describe svc myapp-production | grep Selector
```

### Scale Operations
```bash
# Scale up
kubectl scale deployment app-v2-canary --replicas=3

# Scale down
kubectl scale deployment app-v1 --replicas=0

# Check replicas
kubectl get deploy -l app=myapp
```

---

## 📊 Traffic Distribution (Canary)

### Pod-Based (Simple Math)
```
Total Pods = v1 pods + v2 pods
v2 Traffic% = (v2 pods / Total) × 100

Examples:
5 v1 + 1 v2 = 17% v2
4 v1 + 2 v2 = 33% v2
3 v1 + 3 v2 = 50% v2
2 v1 + 4 v2 = 67% v2
0 v1 + 5 v2 = 100% v2
```

### Gateway API (Precise)
```yaml
backendRefs:
  - name: v1-service
    weight: 90  # 90%
  - name: v2-service
    weight: 10  # 10%
```

---

## 🛠️ Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp' | head -20
```

### Service Not Routing
```bash
kubectl get endpoints <service-name>
kubectl describe svc <service-name>
```

### Check Image
```bash
kubectl get pods -l app=myapp -o jsonpath='{.items[*].spec.containers[0].image}'
```

### Force Delete Pod
```bash
kubectl delete pod <pod-name> --force --grace-period=0
```

---

## ⚠️ Pre-Flight Checklist

### Before Canary Deploy:
- [ ] v1 is stable in production
- [ ] v2 tested in staging
- [ ] Monitoring dashboards ready
- [ ] Team member standing by
- [ ] Rollback command ready

### Before Blue-Green Switch:
- [ ] Blue serving production (100%)
- [ ] Green fully deployed and ready
- [ ] Green tested via direct URL
- [ ] No errors in Green logs
- [ ] Blue will remain for rollback
- [ ] Team ready for instant action

---

## 📈 Monitoring Metrics

### Key Metrics to Watch:
1. **Error Rate** (should be < 1%)
2. **Response Time** (p50, p95, p99)
3. **CPU Usage** (should be < 80%)
4. **Memory Usage** (should be < 80%)
5. **Request Count** (should match expectations)

### Quick Metric Commands:
```bash
# Error count
kubectl logs -l version=v2 --since=5m | grep ERROR | wc -l

# Pod resources
kubectl top pods -l app=myapp

# Pod status
kubectl get pods -l app=myapp --field-selector=status.phase=Running
```

---

## 🔄 Rollback Decision Matrix

| Condition | Canary Action | Blue-Green Action |
|-----------|--------------|-------------------|
| Error rate > 5% | Scale v2 to 0 | Switch to Blue |
| Response time > 2x | Scale v2 down | Switch to Blue |
| Memory leak | Delete v2 | Switch to Blue |
| Crashes | Delete v2 | Switch to Blue |
| Minor issues | Reduce v2% | Monitor more |
| User complaints | Investigate | Consider rollback |

---

## 💡 Pro Tips

### Canary:
```bash
# Start small (5-10%)
kubectl scale deployment app-v2-canary --replicas=1

# Wait & monitor (30 min each stage)
watch kubectl top pods -l version=v2

# Increase gradually
# 10% → 30% → 50% → 70% → 100%
```

### Blue-Green:
```bash
# Always test Green first
curl http://green.saudicloud.com

# Keep Blue running for 24h after switch
# Easy rollback if issues found later

# Use low-traffic time for switch
# (e.g., 2 AM on weekday)
```

---

## 🎯 When to Use What

### Use Canary when:
- First time deploying major feature
- High-risk changes
- Want gradual validation
- Have good monitoring

### Use Blue-Green when:
- Need instant rollback
- Zero downtime critical
- Can afford resources
- Want all users on same version

### Use Rolling Update when:
- Low-risk changes
- Limited resources
- Simple stateless app
- Dev/staging environment

---

## 🔗 Quick Links

### Canary:
- Guide: [`canary/CANARY-GUIDE.md`](./canary/CANARY-GUIDE.md)
- Files: [`canary/`](./canary/)

### Blue-Green:
- Guide: [`blue-green/BLUE-GREEN-GUIDE.md`](./blue-green/BLUE-GREEN-GUIDE.md)
- Files: [`blue-green/`](./blue-green/)

### Comparison:
- Detailed: [`COMPARISON.md`](./COMPARISON.md)
- Overview: [`README.md`](./README.md)

---

## 🚨 Emergency Commands

### EMERGENCY ROLLBACK (Canary):
```bash
kubectl scale deployment app-v2-canary --replicas=0
kubectl scale deployment app-v1 --replicas=5
```

### EMERGENCY ROLLBACK (Blue-Green):
```bash
kubectl apply -f blue-green/08-switch-to-blue.yaml
# Or instant:
kubectl patch svc myapp-production -p '{"spec":{"selector":{"environment":"blue"}}}'
```

### NUCLEAR OPTION (Delete Everything):
```bash
kubectl delete deployment app-v2-canary
# or
kubectl delete deployment app-green
```

---

## 📱 Keep This Handy

Save these URLs on your phone for on-call emergencies:
- Monitoring Dashboard
- Kubernetes Dashboard
- This Cheat Sheet
- Team Contact Numbers

Print this page and keep it near your desk! 📄
