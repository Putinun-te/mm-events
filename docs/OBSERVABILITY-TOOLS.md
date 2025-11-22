# Observability Tools Guide

## Overview

Observability = Monitoring + Logging + Tracing

## Tools Stack

### 1. Prometheus (Metrics)
**What:** Time-series database for metrics
**Use:** Monitor CPU, memory, requests, errors

**Deploy:**
```bash
kubectl apply -f k8s/monitoring/prometheus.yaml
```

**Access:**
```
http://prometheus-service:9090
```

**Metrics:**
- Request rate
- Error rate
- Response time
- Resource usage

---

### 2. Grafana (Visualization)
**What:** Dashboard for metrics visualization
**Use:** Create dashboards, alerts

**Deploy:**
```bash
kubectl apply -f k8s/monitoring/grafana.yaml
```

**Access:**
```
http://grafana-service:3000
User: admin
Pass: admin
```

**Dashboards:**
- Application metrics
- Infrastructure metrics
- Business metrics

---

### 3. CloudWatch (AWS Native)
**What:** AWS monitoring service
**Use:** AWS resources monitoring

**Metrics:**
- EC2 CPU/Memory
- RDS connections
- EKS cluster health
- Lambda invocations

**Setup:**
```bash
aws cloudwatch put-metric-data \
  --namespace Concert/App \
  --metric-name RequestCount \
  --value 1
```

---

### 4. ELK Stack (Logging)
**Components:**
- Elasticsearch: Store logs
- Logstash: Process logs
- Kibana: Visualize logs

**Use:** Centralized logging

---

### 5. Jaeger (Tracing)
**What:** Distributed tracing
**Use:** Track requests across services

**Deploy:**
```bash
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/deploy/crds/jaegertracing.io_jaegers_crd.yaml
```

---

## Quick Setup

### Minimal (Free)
```
CloudWatch (AWS) + Application Logs
Cost: Free tier
```

### Standard
```
Prometheus + Grafana + CloudWatch
Cost: ~$10-20/month
```

### Enterprise
```
Prometheus + Grafana + ELK + Jaeger + CloudWatch
Cost: ~$100+/month
```

---

## Recommended for Concert App

### Phase 1: Start Simple
```
✅ CloudWatch (AWS metrics)
✅ Application logs to files
✅ Basic health checks
```

### Phase 2: Add Monitoring
```
✅ Prometheus (metrics)
✅ Grafana (dashboards)
✅ Alerts
```

### Phase 3: Full Observability
```
✅ ELK Stack (centralized logs)
✅ Jaeger (tracing)
✅ Custom dashboards
```

---

## Key Metrics to Monitor

### Application
- Request rate (req/sec)
- Error rate (%)
- Response time (ms)
- Active users

### Infrastructure
- CPU usage (%)
- Memory usage (%)
- Disk usage (%)
- Network I/O

### Business
- Bookings per hour
- Revenue
- User signups
- Conversion rate

---

## Alerts Setup

### Critical
- Service down
- Error rate > 5%
- Response time > 2s
- CPU > 90%

### Warning
- Error rate > 1%
- Response time > 1s
- CPU > 70%
- Memory > 80%

---

## Cost Comparison

| Tool | Cost | Complexity |
|------|------|------------|
| CloudWatch | Free tier | Low |
| Prometheus | Free (self-hosted) | Medium |
| Grafana | Free (self-hosted) | Medium |
| ELK Stack | $50-200/month | High |
| Datadog | $15/host/month | Low |
| New Relic | $25/host/month | Low |

---

## Implementation

### 1. Deploy Monitoring
```bash
kubectl apply -f k8s/monitoring/
```

### 2. Configure Alerts
```yaml
# prometheus-alerts.yaml
groups:
- name: app
  rules:
  - alert: HighErrorRate
    expr: rate(http_errors[5m]) > 0.05
    annotations:
      summary: High error rate detected
```

### 3. Create Dashboards
- Import Grafana dashboards
- Customize for your metrics
- Share with team

### 4. Set Up Logging
```yaml
# fluentd-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
    </source>
```

---

## Best Practices

1. **Start Simple:** CloudWatch + basic logs
2. **Add Gradually:** Prometheus → Grafana → ELK
3. **Monitor What Matters:** Focus on user impact
4. **Set Alerts:** But not too many
5. **Review Regularly:** Adjust thresholds
6. **Document:** What each metric means
7. **Test Alerts:** Ensure they work

---

## Conclusion

**Recommended Stack:**
```
Prometheus (metrics) + Grafana (dashboards) + CloudWatch (AWS)
```

**Cost:** ~$10-20/month
**Complexity:** Medium
**Value:** High
