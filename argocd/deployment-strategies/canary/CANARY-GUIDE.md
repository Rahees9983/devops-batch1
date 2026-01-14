# Canary Deployment Strategy

## What is Canary Deployment?

Canary deployment is a progressive rollout strategy where you gradually shift traffic from an old version to a new version. It's named after the "canary in a coal mine" - you send a small amount of traffic to test the waters before fully committing.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  Canary Deployment Flow                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Stage 1: Initial State (100% v1)                       │
│  ┌────────┐                                             │
│  │   v1   │ ◄─── 100% traffic                           │
│  │ 5 pods │                                             │
│  └────────┘                                             │
│                                                          │
│  Stage 2: Deploy Canary (90% v1, 10% v2)                │
│  ┌────────┐                                             │
│  │   v1   │ ◄─── 90% traffic                            │
│  │ 5 pods │                                             │
│  └────────┘                                             │
│  ┌────────┐                                             │
│  │   v2   │ ◄─── 10% traffic (canary)                   │
│  │ 1 pod  │                                             │
│  └────────┘                                             │
│                                                          │
│  Stage 3: Increase Canary (70% v1, 30% v2)              │
│  ┌────────┐                                             │
│  │   v1   │ ◄─── 70% traffic                            │
│  │ 4 pods │                                             │
│  └────────┘                                             │
│  ┌────────┐                                             │
│  │   v2   │ ◄─── 30% traffic                            │
│  │ 2 pods │                                             │
│  └────────┘                                             │
│                                                          │
│  Stage 4: Majority Canary (30% v1, 70% v2)              │
│  ┌────────┐                                             │
│  │   v1   │ ◄─── 30% traffic                            │
│  │ 2 pods │                                             │
│  └────────┘                                             │
│  ┌────────┐                                             │
│  │   v2   │ ◄─── 70% traffic                            │
│  │ 4 pods │                                             │
│  └────────┘                                             │
│                                                          │
│  Stage 5: Complete (100% v2)                            │
│  ┌────────┐                                             │
│  │   v2   │ ◄─── 100% traffic                           │
│  │ 5 pods │                                             │
│  └────────┘                                             │
│  (Delete v1)                                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Advantages

✅ **Low Risk**: Only small percentage of users affected if issues occur
✅ **Real Production Testing**: Test with actual production traffic
✅ **Quick Rollback**: Can rollback by adjusting traffic percentage
✅ **Gradual Migration**: Slowly increase confidence in new version
✅ **Monitor Impact**: Observe metrics before full rollout

## Disadvantages

❌ **Complex Setup**: Requires traffic management (Ingress or Gateway API)
❌ **Resource Overhead**: Running multiple versions simultaneously
❌ **Monitoring Required**: Need good observability to detect issues
❌ **Session Handling**: May need sticky sessions for stateful apps

---

## Implementation Approaches

### Approach 1: Pod-Based Traffic Distribution (Simplest)

This uses Kubernetes native load balancing based on pod count.

**Traffic Distribution:**
```
Total Pods = v1 pods + v2 pods
Traffic to v2 = (v2 pods / Total Pods) × 100%
```

**Example:**
- 5 v1 pods + 1 v2 pod = 6 total pods
- v2 gets: (1/6) × 100% = ~16.7% traffic

**Files:**
- `01-deployment-v1.yaml` - Stable version with 5 replicas
- `02-deployment-v2-canary.yaml` - Canary version with 1 replica
- `03-service.yaml` - Service selecting both versions
- `04-ingress.yaml` - Standard Ingress

**Pros:**
- Simple, no special tools needed
- Uses native Kubernetes load balancing

**Cons:**
- Traffic split not precise
- Must scale pods to change traffic percentage

---

### Approach 2: Gateway API Weight-Based (Recommended)

Uses Gateway API's native traffic splitting feature.

**Traffic Distribution:**
```yaml
backendRefs:
  - name: v1-service
    weight: 90  # 90% to v1
  - name: v2-service
    weight: 10  # 10% to v2
```

**Files:**
- `05-gateway-api-canary.yaml` - HTTPRoute with weighted backends

**Pros:**
- Precise traffic control
- Independent of pod count
- Easy to adjust percentages

**Cons:**
- Requires Gateway API support

---

## Step-by-Step Deployment Guide

### Method 1: Pod-Based Canary

#### Step 1: Deploy Stable Version (v1)

```bash
# Deploy v1 with 5 replicas (100% traffic)
kubectl apply -f 01-deployment-v1.yaml

# Create service
kubectl apply -f 03-service.yaml

# Create ingress
kubectl apply -f 04-ingress.yaml

# Verify
kubectl get pods -l app=myapp
kubectl get svc myapp-service
```

#### Step 2: Deploy Canary (10% traffic)

```bash
# Deploy v2 with 1 replica
# Total: 5 v1 + 1 v2 = 6 pods
# v2 gets: 1/6 = 16.7% traffic
kubectl apply -f 02-deployment-v2-canary.yaml

# Verify both versions running
kubectl get pods -l app=myapp
kubectl get pods -l version=v1
kubectl get pods -l version=v2
```

#### Step 3: Monitor Canary

```bash
# Watch pods
kubectl get pods -l app=myapp -w

# Check logs for errors
kubectl logs -l version=v2 -f

# Test the service multiple times
for i in {1..20}; do
  curl http://canary.saudicloud.com
  sleep 1
done

# You should see v1 responses ~83% and v2 responses ~17%
```

#### Step 4: Increase Canary Traffic (30%)

```bash
# Scale v2 to 2 replicas
# Total: 5 v1 + 2 v2 = 7 pods
# v2 gets: 2/7 = 28.5% traffic
kubectl scale deployment app-v2-canary --replicas=2

# Verify
kubectl get pods -l app=myapp
```

#### Step 5: Continue Progressive Rollout

```bash
# 50% traffic: 3 v1 + 3 v2
kubectl scale deployment app-v1 --replicas=3
kubectl scale deployment app-v2-canary --replicas=3

# 70% to v2: 2 v1 + 4 v2
kubectl scale deployment app-v1 --replicas=2
kubectl scale deployment app-v2-canary --replicas=4

# 100% to v2: 0 v1 + 5 v2
kubectl scale deployment app-v1 --replicas=0
kubectl scale deployment app-v2-canary --replicas=5
```

#### Step 6: Complete Migration

```bash
# Delete v1 deployment
kubectl delete deployment app-v1

# Rename v2 (optional)
kubectl patch deployment app-v2-canary -p '{"metadata":{"name":"app-v1"}}'
```

#### Rollback (if issues detected)

```bash
# Quick rollback: scale v2 to 0
kubectl scale deployment app-v2-canary --replicas=0

# Or delete v2 completely
kubectl delete deployment app-v2-canary

# Scale v1 back to normal
kubectl scale deployment app-v1 --replicas=5
```

---

### Method 2: Gateway API Weight-Based

#### Step 1: Deploy Both Versions

```bash
# Deploy v1
kubectl apply -f 01-deployment-v1.yaml

# Deploy v2
kubectl apply -f 02-deployment-v2-canary.yaml

# Deploy services and HTTPRoute with weights
kubectl apply -f 05-gateway-api-canary.yaml
```

#### Step 2: Start with 10% Canary

Edit `05-gateway-api-canary.yaml`:
```yaml
backendRefs:
  - name: myapp-v1-service
    weight: 90
  - name: myapp-v2-service
    weight: 10
```

```bash
kubectl apply -f 05-gateway-api-canary.yaml
```

#### Step 3: Increase to 30%

```yaml
backendRefs:
  - name: myapp-v1-service
    weight: 70
  - name: myapp-v2-service
    weight: 30
```

```bash
kubectl apply -f 05-gateway-api-canary.yaml
```

#### Step 4: Continue to 50%, 70%, 100%

```yaml
# 50%
weights: 50/50

# 70%
weights: 30/70

# 100%
weights: 0/100
```

#### Step 5: Complete Migration

```bash
# Delete v1 deployment
kubectl delete deployment app-v1

# Update HTTPRoute to only use v2
```

---

## Monitoring Canary Deployments

### Key Metrics to Watch:

1. **Error Rate**
```bash
# Compare error rates between versions
kubectl logs -l version=v1 | grep ERROR | wc -l
kubectl logs -l version=v2 | grep ERROR | wc -l
```

2. **Response Time**
```bash
# Use monitoring tools (Prometheus, Grafana)
# Watch p50, p95, p99 latencies
```

3. **CPU/Memory Usage**
```bash
kubectl top pods -l version=v2
```

4. **Traffic Distribution**
```bash
# Count requests to each version
for i in {1..100}; do
  curl -s http://canary.saudicloud.com | grep version
done | sort | uniq -c
```

### Success Criteria:

✅ Error rate < 1%
✅ Response time similar to v1
✅ No memory leaks
✅ CPU usage normal
✅ No user complaints

### Rollback Criteria:

❌ Error rate > 5%
❌ Response time > 2x v1
❌ Memory leaks detected
❌ CPU spikes
❌ User complaints

---

## Testing Your Canary

### Load Testing Script

```bash
#!/bin/bash
# test-canary.sh

ENDPOINT="http://canary.saudicloud.com"
V1_COUNT=0
V2_COUNT=0
TOTAL=100

echo "Testing canary deployment with $TOTAL requests..."

for i in $(seq 1 $TOTAL); do
  RESPONSE=$(curl -s $ENDPOINT)

  if echo "$RESPONSE" | grep -q "v1"; then
    ((V1_COUNT++))
  elif echo "$RESPONSE" | grep -q "v2"; then
    ((V2_COUNT++))
  fi

  sleep 0.1
done

echo "Results:"
echo "v1: $V1_COUNT requests ($((V1_COUNT * 100 / TOTAL))%)"
echo "v2: $V2_COUNT requests ($((V2_COUNT * 100 / TOTAL))%)"
```

### Monitor Pods During Canary

```bash
# Terminal 1: Watch pods
watch kubectl get pods -l app=myapp

# Terminal 2: Watch service endpoints
watch kubectl get endpoints myapp-service

# Terminal 3: Stream logs
kubectl logs -l version=v2 -f

# Terminal 4: Run load test
./test-canary.sh
```

---

## Advanced Canary Patterns

### 1. Header-Based Canary (Dark Launch)

Route specific users to canary based on headers:

```yaml
# Using Gateway API
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp-dark-launch
spec:
  rules:
    # Beta users get v2
    - matches:
        - headers:
            - name: X-User-Type
              value: beta
      backendRefs:
        - name: myapp-v2-service
          port: 80

    # Everyone else gets v1
    - backendRefs:
        - name: myapp-v1-service
          port: 80
```

### 2. Geographic Canary

Deploy canary to specific region first:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2-canary-us
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: topology.kubernetes.io/region
                operator: In
                values:
                - us-east-1
```

### 3. Automated Canary with Flagger

Flagger automates progressive delivery:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-v2
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
    - name: request-duration
      thresholdRange:
        max: 500
```

---

## Canary Deployment Checklist

### Before Deployment:
- [ ] v2 tested in staging
- [ ] Monitoring dashboards ready
- [ ] Rollback plan documented
- [ ] Success/failure criteria defined
- [ ] Team notified

### During Deployment:
- [ ] Deploy canary with low traffic (5-10%)
- [ ] Monitor for 30 minutes
- [ ] Check error rates
- [ ] Check response times
- [ ] Check resource usage
- [ ] Increase traffic gradually

### After Each Stage:
- [ ] Wait observation period (15-30 min)
- [ ] Compare metrics vs baseline
- [ ] Check alerts
- [ ] Review logs
- [ ] Get team approval

### Completion:
- [ ] 100% traffic to v2
- [ ] No errors for 1 hour
- [ ] Delete v1 deployment
- [ ] Update documentation
- [ ] Post-mortem (if issues)

---

## Common Commands

```bash
# Deploy canary
kubectl apply -f 01-deployment-v1.yaml
kubectl apply -f 02-deployment-v2-canary.yaml
kubectl apply -f 03-service.yaml
kubectl apply -f 04-ingress.yaml

# Check status
kubectl get deployments -l app=myapp
kubectl get pods -l app=myapp
kubectl get svc myapp-service

# Scale canary
kubectl scale deployment app-v2-canary --replicas=2

# Monitor traffic distribution
for i in {1..50}; do curl -s http://canary.saudicloud.com; done | sort | uniq -c

# Rollback
kubectl scale deployment app-v2-canary --replicas=0
# or
kubectl delete deployment app-v2-canary

# Complete migration
kubectl delete deployment app-v1
kubectl scale deployment app-v2-canary --replicas=5
```

---

## Best Practices

1. **Start Small**: Begin with 5-10% traffic
2. **Monitor Closely**: Watch metrics in real-time
3. **Go Slow**: Wait 15-30 min between increases
4. **Automate**: Use tools like Flagger or Argo Rollouts
5. **Have Rollback Plan**: Be ready to revert quickly
6. **Test Thoroughly**: Staging should catch most issues
7. **Document**: Keep deployment log
8. **Communicate**: Keep team informed

---

## Troubleshooting

**Issue**: Traffic not splitting as expected
```bash
# Check service selector
kubectl describe svc myapp-service

# Verify pod labels
kubectl get pods -l app=myapp --show-labels

# Check endpoints
kubectl get endpoints myapp-service
```

**Issue**: Canary pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check image pull
kubectl get events --sort-by='.lastTimestamp'
```

**Issue**: Different behavior in canary
```bash
# Check environment variables
kubectl exec <pod-name> -- env

# Check config maps
kubectl describe cm <configmap-name>

# Compare versions
kubectl diff -f 01-deployment-v1.yaml -f 02-deployment-v2-canary.yaml
```

---

## Summary

Canary deployment is ideal when:
- You want to minimize risk
- You have good monitoring
- You can gradually increase traffic
- You need real production testing

Use Gateway API for precise traffic control or pod scaling for simplicity.
