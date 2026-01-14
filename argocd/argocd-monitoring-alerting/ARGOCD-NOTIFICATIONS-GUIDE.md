# ArgoCD Notifications Setup Guide

This guide covers the complete setup for ArgoCD Slack notifications.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step 1: Create Slack App & Get Token](#step-1-create-slack-app--get-token)
4. [Step 2: Create Kubernetes Secret](#step-2-create-kubernetes-secret)
5. [Step 3: Configure Notifications ConfigMap](#step-3-configure-notifications-configmap)
6. [Step 4: Add Annotations to Applications](#step-4-add-annotations-to-applications)
7. [Step 5: Apply and Verify](#step-5-apply-and-verify)
8. [Troubleshooting](#troubleshooting)
9. [Reference](#reference)

---

## Prerequisites

- ArgoCD installed with notifications controller enabled
- Slack workspace with permission to create apps
- kubectl access to the cluster

Verify notifications controller is running:
```bash
kubectl get pods -n argocd | grep notifications
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ArgoCD Cluster                               │
│                                                                     │
│  ┌──────────────┐    ┌────────────────────┐    ┌────────────────┐  │
│  │   ArgoCD     │    │   Notifications    │    │  ConfigMap     │  │
│  │ Application  │───►│   Controller       │◄───│  (templates,   │  │
│  │ (with        │    │                    │    │   triggers)    │  │
│  │ annotations) │    │                    │    │                │  │
│  └──────────────┘    └─────────┬──────────┘    └────────────────┘  │
│                                │                                    │
│                                │              ┌────────────────┐   │
│                                │              │    Secret      │   │
│                                │◄─────────────│  (slack-token) │   │
│                                │              └────────────────┘   │
└────────────────────────────────┼────────────────────────────────────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │     Slack      │
                        │   Workspace    │
                        │  #channel      │
                        └────────────────┘
```

---

## Step 1: Create Slack App & Get Token

### 1.1 Create a Slack App

1. Go to https://api.slack.com/apps
2. Click **"Create New App"**
3. Select **"From scratch"**
4. Enter:
   - App Name: `ArgoCD Notifications`
   - Workspace: Select your workspace
5. Click **"Create App"**

### 1.2 Configure Bot Token Scopes

1. In the left sidebar, click **"OAuth & Permissions"**
2. Scroll to **"Scopes"** → **"Bot Token Scopes"**
3. Add these scopes:
   - `chat:write` - Send messages
   - `chat:write.public` - Send to channels without joining
   - `incoming-webhook` (optional)

### 1.3 Install App to Workspace

1. Scroll up to **"OAuth Tokens for Your Workspace"**
2. Click **"Install to Workspace"**
3. Review permissions and click **"Allow"**
4. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

### 1.4 Invite Bot to Channel

In Slack:
```
/invite @ArgoCD Notifications
```
Or add the bot to your channel settings.

---

## Step 2: Create Kubernetes Secret

Create a secret to store the Slack token:

```yaml
# argocd-notifications-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
type: Opaque
stringData:
  slack-token: "xoxb-your-actual-slack-bot-token-here"
```

Apply:
```bash
kubectl apply -f argocd-notifications-secret.yaml
```

Verify:
```bash
kubectl get secret argocd-notifications-secret -n argocd
```

---

## Step 3: Configure Notifications ConfigMap

The ConfigMap contains three main parts:
- **Context**: Global variables (like ArgoCD URL)
- **Templates**: Message format for notifications
- **Triggers**: Conditions that fire notifications

### 3.1 Full ConfigMap Example

```yaml
# argocd-notifications-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  # ===================
  # CONTEXT
  # ===================
  # Use external URL for clickable links in Slack
  context: |
    argocdUrl: https://8.213.84.167

  # ===================
  # SERVICE CONFIGURATION
  # ===================
  service.slack: |
    token: $slack-token
    username: argocd-bot
    icon: ":rocket:"

  # ===================
  # TEMPLATES
  # ===================

  # Template: Sync Succeeded (Green)
  template.app-sync-succeeded: |
    message: |
      :white_check_mark: Application {{.app.metadata.name}} has been synced successfully!
    slack:
      attachments: |
        [{
          "title": "{{.app.metadata.name}}",
          "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
          "color": "#18be52",
          "fields": [{
            "title": "Sync Status",
            "value": "{{.app.status.sync.status}}",
            "short": true
          }, {
            "title": "Health Status",
            "value": "{{.app.status.health.status}}",
            "short": true
          }, {
            "title": "Repository",
            "value": "{{.app.spec.source.repoURL}}",
            "short": true
          }, {
            "title": "Revision",
            "value": "{{.app.status.sync.revision}}",
            "short": true
          }]
        }]

  # Template: Sync Failed (Red)
  template.app-sync-failed: |
    message: |
      :x: Application {{.app.metadata.name}} sync has FAILED!
    slack:
      attachments: |
        [{
          "title": "{{.app.metadata.name}} - SYNC FAILED",
          "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
          "color": "#E96D76",
          "fields": [{
            "title": "Sync Status",
            "value": "{{.app.status.sync.status}}",
            "short": true
          }, {
            "title": "Health Status",
            "value": "{{.app.status.health.status}}",
            "short": true
          }]
        }]

  # Template: Health Degraded (Orange)
  template.app-health-degraded: |
    message: |
      :warning: Application {{.app.metadata.name}} health is DEGRADED!
    slack:
      attachments: |
        [{
          "title": "{{.app.metadata.name}} - HEALTH DEGRADED",
          "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
          "color": "#f4c030",
          "fields": [{
            "title": "Health Status",
            "value": "{{.app.status.health.status}}",
            "short": true
          }]
        }]

  # Template: Out of Sync (Yellow)
  template.app-out-of-sync: |
    message: |
      :arrows_counterclockwise: Application {{.app.metadata.name}} is OUT OF SYNC!
    slack:
      attachments: |
        [{
          "title": "{{.app.metadata.name}} - OUT OF SYNC",
          "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
          "color": "#f4c030",
          "fields": [{
            "title": "Sync Status",
            "value": "{{.app.status.sync.status}}",
            "short": true
          }]
        }]

  # ===================
  # TRIGGERS
  # ===================

  # Trigger: On Sync Succeeded
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
      send: [app-sync-succeeded]

  # Trigger: On Sync Failed
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]

  # Trigger: On Health Degraded
  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]

  # Trigger: On Out of Sync
  trigger.on-sync-status-unknown: |
    - when: app.status.sync.status == 'OutOfSync'
      send: [app-out-of-sync]
```

Apply:
```bash
kubectl apply -f argocd-notifications-cm.yaml
```

---

## Step 4: Add Annotations to Applications

### 4.1 Annotation Format

```
notifications.argoproj.io/subscribe.<trigger-name>.<service>: <destination>
```

### 4.2 Available Triggers & Annotations

| Trigger Name | Annotation | Description |
|--------------|------------|-------------|
| `on-sync-succeeded` | `notifications.argoproj.io/subscribe.on-sync-succeeded.slack: <channel>` | Sync completed successfully |
| `on-sync-failed` | `notifications.argoproj.io/subscribe.on-sync-failed.slack: <channel>` | Sync failed |
| `on-health-degraded` | `notifications.argoproj.io/subscribe.on-health-degraded.slack: <channel>` | App health degraded |
| `on-sync-status-unknown` | `notifications.argoproj.io/subscribe.on-sync-status-unknown.slack: <channel>` | App is out of sync |

### 4.3 Example Application with All Notifications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    # Slack channel name (without #)
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: devops-alerts
    notifications.argoproj.io/subscribe.on-sync-failed.slack: devops-alerts
    notifications.argoproj.io/subscribe.on-health-degraded.slack: devops-alerts
    notifications.argoproj.io/subscribe.on-sync-status-unknown.slack: devops-alerts
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
```

### 4.4 Add Annotations to Existing Application

**Option 1: kubectl patch**
```bash
kubectl patch app <app-name> -n argocd --type=merge -p '{
  "metadata": {
    "annotations": {
      "notifications.argoproj.io/subscribe.on-sync-succeeded.slack": "devops-alerts",
      "notifications.argoproj.io/subscribe.on-sync-failed.slack": "devops-alerts"
    }
  }
}'
```

**Option 2: kubectl edit**
```bash
kubectl edit app <app-name> -n argocd
```

Then add annotations under `metadata.annotations`.

**Option 3: ArgoCD UI**
1. Open ArgoCD UI
2. Go to Application → Details
3. Click Edit
4. Add annotations in the YAML editor

---

## Step 5: Apply and Verify

### 5.1 Apply All Resources

```bash
# 1. Apply secret (update token first!)
kubectl apply -f argocd-notifications-secret.yaml

# 2. Apply ConfigMap
kubectl apply -f argocd-notifications-cm.yaml

# 3. Restart notifications controller to pick up changes
kubectl rollout restart deployment argocd-notifications-controller -n argocd

# 4. Wait for rollout
kubectl rollout status deployment argocd-notifications-controller -n argocd
```

### 5.2 Verify Setup

```bash
# Check notifications controller logs
kubectl logs -n argocd deployment/argocd-notifications-controller

# Check ConfigMap is loaded
kubectl get cm argocd-notifications-cm -n argocd -o yaml

# Check Secret exists
kubectl get secret argocd-notifications-secret -n argocd

# Check application has annotations
kubectl get app <app-name> -n argocd -o jsonpath='{.metadata.annotations}'
```

### 5.3 Test Notification

Trigger a sync on your application:
```bash
argocd app sync <app-name>
```

Or via kubectl:
```bash
kubectl patch app <app-name> -n argocd --type=merge -p '{"operation": {"initiatedBy": {"username": "test"}, "sync": {}}}'
```

---

## Troubleshooting

### Issue: No notifications received

1. **Check controller logs:**
   ```bash
   kubectl logs -n argocd deployment/argocd-notifications-controller -f
   ```

2. **Verify secret is correct:**
   ```bash
   kubectl get secret argocd-notifications-secret -n argocd -o jsonpath='{.data.slack-token}' | base64 -d
   ```

3. **Check ConfigMap syntax:**
   ```bash
   kubectl get cm argocd-notifications-cm -n argocd -o yaml
   ```

4. **Verify annotations on app:**
   ```bash
   kubectl get app <app-name> -n argocd -o yaml | grep -A 10 annotations
   ```

### Issue: "channel_not_found" error

- Ensure the Slack channel exists
- Invite the bot to the channel: `/invite @ArgoCD Notifications`
- Use channel name without `#` prefix

### Issue: "invalid_auth" error

- Verify the Slack token is correct
- Check token hasn't been revoked
- Ensure token has required scopes (`chat:write`, `chat:write.public`)

### Issue: Template not rendering

- Check YAML indentation in ConfigMap
- Verify template name matches trigger's `send` list
- Test with simple message first

---

## Reference

### Available Template Variables

| Variable | Description |
|----------|-------------|
| `{{.app.metadata.name}}` | Application name |
| `{{.app.metadata.namespace}}` | Application namespace |
| `{{.app.spec.source.repoURL}}` | Git repository URL |
| `{{.app.spec.source.path}}` | Path in repository |
| `{{.app.spec.source.targetRevision}}` | Target branch/tag |
| `{{.app.spec.destination.server}}` | Destination cluster |
| `{{.app.spec.destination.namespace}}` | Destination namespace |
| `{{.app.status.sync.status}}` | Sync status (Synced/OutOfSync) |
| `{{.app.status.sync.revision}}` | Current revision (commit SHA) |
| `{{.app.status.health.status}}` | Health status |
| `{{.app.status.operationState.phase}}` | Operation phase |
| `{{.context.argocdUrl}}` | ArgoCD URL from context |

### Trigger Conditions

| Condition | Expression |
|-----------|------------|
| Sync Succeeded | `app.status.operationState.phase in ['Succeeded']` |
| Sync Failed | `app.status.operationState.phase in ['Error', 'Failed']` |
| Healthy | `app.status.health.status == 'Healthy'` |
| Degraded | `app.status.health.status == 'Degraded'` |
| Out of Sync | `app.status.sync.status == 'OutOfSync'` |
| Synced | `app.status.sync.status == 'Synced'` |

### Files Summary

| File | Purpose |
|------|---------|
| `argocd-notifications-secret.yaml` | Slack token storage |
| `argocd-notifications-cm.yaml` | Templates, triggers, service config |
| `sample-app-with-notifications.yaml` | Example application |

---

## Quick Start Checklist

- [ ] Create Slack App at https://api.slack.com/apps
- [ ] Add `chat:write` and `chat:write.public` scopes
- [ ] Install app to workspace and copy Bot Token
- [ ] Invite bot to Slack channel
- [ ] Update `argocd-notifications-secret.yaml` with token
- [ ] Apply secret: `kubectl apply -f argocd-notifications-secret.yaml`
- [ ] Update `argocd-notifications-cm.yaml` with your ArgoCD URL
- [ ] Apply ConfigMap: `kubectl apply -f argocd-notifications-cm.yaml`
- [ ] Restart controller: `kubectl rollout restart deployment argocd-notifications-controller -n argocd`
- [ ] Add annotations to your ArgoCD Application
- [ ] Test by syncing the application
