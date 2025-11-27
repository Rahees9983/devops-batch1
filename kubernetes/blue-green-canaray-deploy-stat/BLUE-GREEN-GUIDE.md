# Blue-Green Deployment Strategy

## What is Blue-Green Deployment?

Blue-Green deployment is a release strategy where you maintain two identical production environments (Blue and Green). At any time, only one environment serves production traffic. When deploying a new version, you deploy to the inactive environment, test it, then switch traffic instantly.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│              Blue-Green Deployment Flow                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Initial State:                                          │
│  ┌──────────┐                    ┌──────────┐           │
│  │   BLUE   │ ◄─── 100%         │  GREEN   │           │
│  │   (v1)   │  Production       │  (idle)  │           │
│  │  5 pods  │                   │  0 pods  │           │
│  └──────────┘                   └──────────┘           │
│                                                          │
│  Deploy New Version to Green:                            │
│  ┌──────────┐                    ┌──────────┐           │
│  │   BLUE   │ ◄─── 100%         │  GREEN   │           │
│  │   (v1)   │  Production       │   (v2)   │           │
│  │  5 pods  │                   │  5 pods  │  ← Deploy │
│  └──────────┘                   └──────────┘           │
│                                      ▲                   │
│                                      └─ Test GREEN       │
│                                                          │
│  Switch Traffic (Instant):                               │
│  ┌──────────┐                    ┌──────────┐           │
│  │   BLUE   │                    │  GREEN   │ ◄─ 100%  │
│  │   (v1)   │                    │   (v2)   │ Production│
│  │  5 pods  │  (standby)         │  5 pods  │           │
│  └──────────┘                    └──────────┘           │
│                                                          │
│  After Verification (Optional):                          │
│  ┌──────────┐                    ┌──────────┐           │
│  │   BLUE   │                    │  GREEN   │ ◄─ 100%  │
│  │  (idle)  │                    │   (v2)   │ Production│
│  │  0 pods  │  ← Scale down      │  5 pods  │           │
│  └──────────┘                    └──────────┘           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Advantages

✅ **Instant Rollback**: Switch back to Blue immediately if issues
✅ **Zero Downtime**: No service interruption during deployment
✅ **Full Testing**: Test Green environment before switching
✅ **Simple**: Easy to understand and implement
✅ **No Gradual Issues**: All users get same version

## Disadvantages

❌ **Resource Intensive**: Need 2x resources during deployment
❌ **Database Migrations**: Complex with schema changes
❌ **Session Handling**: Active sessions may need migration
❌ **Expensive**: Running duplicate infrastructure

---

## Implementation Approach

### Architecture Components:

1. **Blue Deployment**: Current production version (v1)
2. **Green Deployment**: New version to be deployed (v2)
3. **Production Service**: Routes traffic to active environment
4. **Blue Service**: Direct access to Blue for testing
5. **Green Service**: Direct access to Green for testing
6. **Ingress**: Three hostnames for production, blue, green

### Traffic Switching Mechanism:

The `myapp-production` service selector determines which environment receives traffic:

```yaml
# Production pointing to BLUE
selector:
  environment: blue  # All traffic to Blue

# Production pointing to GREEN
selector:
  environment: green  # All traffic to Green
```

---

## Step-by-Step Deployment Guide

### Phase 1: Initial Setup (Blue is Active)

#### Step 1: Deploy Blue Environment (v1)

```bash
# Deploy Blue deployment with v1
kubectl apply -f 01-deployment-blue-v1.yaml

# Create Blue service
kubectl apply -f 04-service-blue.yaml

# Create production service (points to Blue)
kubectl apply -f 03-service-production.yaml

# Create ingress
kubectl apply -f 06-ingress.yaml

# Verify Blue is running
kubectl get pods -l environment=blue
kubectl get svc myapp-blue myapp-production
```

#### Step 2: Test Blue via Production

```bash
# Test production endpoint
curl http://bluegreen.saudicloud.com
# Should return v1 response

# Test Blue directly
curl http://blue.saudicloud.com
# Should return v1 response
```

---

### Phase 2: Deploy New Version to Green

#### Step 3: Deploy Green Environment (v2)

```bash
# Deploy Green deployment with v2
kubectl apply -f 02-deployment-green-v2.yaml

# Create Green service
kubectl apply -f 05-service-green.yaml

# Wait for Green pods to be ready
kubectl wait --for=condition=ready pod -l environment=green --timeout=300s

# Verify Green is running
kubectl get pods -l environment=green
kubectl get svc myapp-green
```

At this point:
- **Blue (v1)**: Serving 100% production traffic
- **Green (v2)**: Running but not receiving production traffic

---

### Phase 3: Test Green Environment

#### Step 4: Comprehensive Testing of Green

```bash
# Test Green directly (not production traffic)
curl http://green.saudicloud.com
# Should return v2 response

# Run smoke tests against Green
for i in {1..20}; do
  curl http://green.saudicloud.com
  sleep 1
done

# Check Green pod logs
kubectl logs -l environment=green --tail=50

# Check Green pod health
kubectl get pods -l environment=green
kubectl describe pods -l environment=green
```

#### Step 5: Run Full Test Suite Against Green

```bash
# Integration tests
./run-integration-tests.sh http://green.saudicloud.com

# Performance tests
ab -n 1000 -c 10 http://green.saudicloud.com/

# Verify metrics
kubectl top pods -l environment=green

# Check for errors in logs
kubectl logs -l environment=green | grep -i error
```

---

### Phase 4: Switch Traffic to Green

#### Step 6: Switch Production Traffic (The Big Moment!)

```bash
# Switch production service to Green
kubectl apply -f 07-switch-to-green.yaml

# Verify the switch
kubectl get svc myapp-production -o yaml | grep environment
# Should show: environment: green

# Verify endpoints
kubectl get endpoints myapp-production
```

**Traffic is now switched!**
- Production traffic: 100% to Green (v2)
- Blue (v1): Still running but idle

#### Step 7: Verify Production on Green

```bash
# Test production endpoint (should now return v2)
curl http://bluegreen.saudicloud.com
# Should return v2 response

# Monitor for issues
kubectl logs -l environment=green -f

# Watch metrics
watch kubectl top pods -l environment=green

# Check error rate
kubectl logs -l environment=green | grep ERROR | wc -l
```

---

### Phase 5: Post-Switch Actions

#### Step 8A: If Everything is Good - Keep Green

```bash
# Monitor Green for 30-60 minutes
# If stable, you can:

# Option 1: Keep Blue as standby (recommended for 24h)
# No action needed, Blue remains ready for instant rollback

# Option 2: Scale down Blue (after confidence period)
kubectl scale deployment app-blue --replicas=0

# Option 3: Delete Blue (only after full confidence)
kubectl delete deployment app-blue
kubectl delete svc myapp-blue
```

#### Step 8B: If Issues Found - Rollback to Blue

```bash
# INSTANT ROLLBACK - Switch back to Blue
kubectl apply -f 08-switch-to-blue.yaml

# Verify rollback
kubectl get svc myapp-production -o yaml | grep environment
# Should show: environment: blue

# Test
curl http://bluegreen.saudicloud.com
# Should return v1 response

# Total rollback time: < 5 seconds!
```

---

### Phase 6: Prepare for Next Deployment

#### Step 9: Cleanup and Prepare Next Cycle

```bash
# After Green is stable and Blue is no longer needed:

# Delete Blue resources
kubectl delete deployment app-blue
kubectl delete svc myapp-blue

# For next deployment:
# Green becomes the new "Blue" (stable version)
# Deploy v3 to a new "Green" deployment
# Repeat the process
```

---

## Alternative: DNS-Based Blue-Green

For external load balancers:

```yaml
# Use different LoadBalancer services
apiVersion: v1
kind: Service
metadata:
  name: myapp-blue-lb
spec:
  type: LoadBalancer
  selector:
    environment: blue
  ports:
  - port: 80
    targetPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  name: myapp-green-lb
spec:
  type: LoadBalancer
  selector:
    environment: green
  ports:
  - port: 80
    targetPort: 8080
```

Switch by updating DNS:
```bash
# Point DNS to Blue LoadBalancer IP
bluegreen.saudicloud.com → <blue-lb-ip>

# Switch DNS to Green LoadBalancer IP
bluegreen.saudicloud.com → <green-lb-ip>
```

---

## Monitoring During Blue-Green

### Before Switch:

```bash
# Check both environments are healthy
kubectl get pods -l app=myapp

# Verify pod counts
echo "Blue pods: $(kubectl get pods -l environment=blue --no-headers | wc -l)"
echo "Green pods: $(kubectl get pods -l environment=green --no-headers | wc -l)"

# Check which is active
kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}'
```

### During Switch:

```bash
# Terminal 1: Watch production service
watch -n 1 'kubectl get svc myapp-production -o yaml | grep environment'

# Terminal 2: Monitor pods
watch kubectl get pods -l app=myapp

# Terminal 3: Continuous health check
while true; do
  curl -s http://bluegreen.saudicloud.com | grep version
  sleep 1
done

# Terminal 4: Watch logs
kubectl logs -l environment=green -f
```

### After Switch:

```bash
# Check error rate
kubectl logs -l environment=green --since=5m | grep ERROR | wc -l

# Check response times
# (Use your monitoring tool: Prometheus, Grafana, etc.)

# Verify no traffic to Blue
kubectl logs -l environment=blue --since=5m | wc -l
# Should be 0 or very low
```

---

## Handling Database Migrations

Blue-Green with database changes is tricky:

### Strategy 1: Backward Compatible Changes

```sql
-- v1 Schema
CREATE TABLE users (
  id INT,
  name VARCHAR(100)
);

-- v2 Schema (add column, don't remove)
ALTER TABLE users ADD COLUMN email VARCHAR(100);

-- Both Blue and Green can work with this!
```

### Strategy 2: Three-Phase Deployment

```
Phase 1: Add new column (deploy with Blue still running)
Phase 2: Deploy Green with code using new column
Phase 3: Remove old column (after Blue is deleted)
```

### Strategy 3: Separate Database Instances

```
Blue → Database Blue (v1 schema)
Green → Database Green (v2 schema)
```

**Note**: This requires data synchronization!

---

## Testing Checklist

### Before Switch to Green:

- [ ] All Green pods are Running and Ready
- [ ] Green responds correctly to health checks
- [ ] Smoke tests pass on Green
- [ ] Integration tests pass on Green
- [ ] Load test shows acceptable performance
- [ ] No errors in Green logs
- [ ] Resource usage (CPU/Memory) is normal
- [ ] Database migrations completed (if any)
- [ ] Rollback plan reviewed

### After Switch to Green:

- [ ] Production endpoint returns v2
- [ ] No increase in error rate
- [ ] Response times acceptable
- [ ] Resource usage stable
- [ ] No user complaints
- [ ] Monitor for 30-60 minutes
- [ ] Blue is ready for instant rollback

### Before Deleting Blue:

- [ ] Green stable for 24+ hours
- [ ] No issues reported
- [ ] Rollback no longer needed
- [ ] Team approval to proceed

---

## Common Commands

```bash
# Initial deployment
kubectl apply -f 01-deployment-blue-v1.yaml
kubectl apply -f 03-service-production.yaml
kubectl apply -f 04-service-blue.yaml
kubectl apply -f 06-ingress.yaml

# Deploy Green
kubectl apply -f 02-deployment-green-v2.yaml
kubectl apply -f 05-service-green.yaml

# Test Green
curl http://green.saudicloud.com

# Switch to Green
kubectl apply -f 07-switch-to-green.yaml

# Verify switch
kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}'

# Rollback to Blue
kubectl apply -f 08-switch-to-blue.yaml

# Check active environment
kubectl get endpoints myapp-production

# Scale down inactive
kubectl scale deployment app-blue --replicas=0

# Delete inactive
kubectl delete deployment app-blue
```

---

## Automated Blue-Green with Scripts

### Switch Script:

```bash
#!/bin/bash
# switch-to-green.sh

echo "Switching production traffic to GREEN..."

kubectl patch service myapp-production -p '{"spec":{"selector":{"environment":"green"}}}'

echo "Verifying switch..."
ACTIVE=$(kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}')

if [ "$ACTIVE" = "green" ]; then
  echo "✓ Successfully switched to GREEN"
  echo "Production is now serving v2"
else
  echo "✗ Switch failed! Active environment: $ACTIVE"
  exit 1
fi

# Test endpoint
echo "Testing production endpoint..."
for i in {1..5}; do
  curl -s http://bluegreen.saudicloud.com | grep version
done
```

### Rollback Script:

```bash
#!/bin/bash
# rollback-to-blue.sh

echo "ROLLING BACK to BLUE..."

kubectl patch service myapp-production -p '{"spec":{"selector":{"environment":"blue"}}}'

echo "Verifying rollback..."
ACTIVE=$(kubectl get svc myapp-production -o jsonpath='{.spec.selector.environment}')

if [ "$ACTIVE" = "blue" ]; then
  echo "✓ Successfully rolled back to BLUE"
  echo "Production is now serving v1"
else
  echo "✗ Rollback failed! Active environment: $ACTIVE"
  exit 1
fi
```

---

## Advanced: Canary with Blue-Green

Combine both strategies:

```bash
# Step 1: Blue is active (100% traffic)

# Step 2: Deploy Green

# Step 3: Route 10% traffic to Green (canary)
# Use Gateway API or Ingress annotations

# Step 4: If canary successful, route 100% to Green

# Step 5: Keep Blue for rollback
```

---

## Blue-Green vs Canary vs Rolling Update

| Feature | Blue-Green | Canary | Rolling Update |
|---------|-----------|--------|----------------|
| **Switch Speed** | Instant | Gradual | Gradual |
| **Rollback Speed** | Instant | Fast | Slow |
| **Resource Usage** | 2x during deploy | ~1.2x | ~1.2x |
| **Testing** | Full test before switch | Test with real traffic | Limited testing |
| **Risk** | Low (tested first) | Very Low (gradual) | Medium |
| **Complexity** | Medium | High | Low |
| **Database** | Challenging | Challenging | Easier |

---

## Troubleshooting

**Issue**: Green pods not starting
```bash
kubectl describe pods -l environment=green
kubectl logs -l environment=green
kubectl get events --sort-by='.lastTimestamp'
```

**Issue**: Production still serving old version after switch
```bash
# Check service selector
kubectl get svc myapp-production -o yaml | grep -A 3 selector

# Check endpoints
kubectl get endpoints myapp-production

# Verify Green pods are ready
kubectl get pods -l environment=green
```

**Issue**: Can't access Green for testing
```bash
# Check Green service
kubectl get svc myapp-green

# Check ingress
kubectl describe ingress myapp-ingress

# Test from inside cluster
kubectl run test-pod --image=curlimages/curl -it --rm -- \
  curl http://myapp-green.default.svc.cluster.local
```

---

## Best Practices

1. **Keep Both Running During Validation**: Don't delete Blue immediately
2. **Test Thoroughly Before Switch**: Green should be production-ready
3. **Monitor After Switch**: Watch metrics for at least 30 minutes
4. **Have Rollback Plan**: Document and practice rollback
5. **Automate**: Use scripts for switching and rollback
6. **DNS TTL**: Keep low TTL if using DNS-based switching
7. **Session Handling**: Consider sticky sessions or session migration
8. **Database**: Plan schema changes carefully

---

## Summary

Blue-Green deployment is ideal when:
- You need instant rollback capability
- You can afford 2x resources temporarily
- You want zero downtime deployments
- You have good testing processes
- Database changes are backward compatible

The key is maintaining two complete environments and switching traffic instantly between them.
