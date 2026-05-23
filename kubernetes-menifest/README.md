# Deploy Online Shopping App on KIND Kubernetes Cluster with Istio

This guide explains how to:

- Create a KIND Kubernetes cluster
- Install Istio
- Deploy an application
- Configure Istio Gateway and VirtualService
- Access the application locally

---

# Architecture

```text
Browser
   ↓
Istio Ingress Gateway
   ↓
Gateway
   ↓
VirtualService
   ↓
Kubernetes Service
   ↓
Application Pods
```

---

# Prerequisites

Install the following tools:

- Docker
- kubectl
- kind
- istioctl

---

# 1. Create KIND Cluster

Create cluster:

```bash
kind create cluster --name kind-zeeshan
```

Verify:

```bash
kubectl cluster-info --context kind-zeeshan
```

Switch context:

```bash
kubectl config use-context kind-zeeshan
```

---

# 2. Install Istio

Download Istio:

```bash
curl -L https://istio.io/downloadIstio | sh -
```

Move into Istio directory:

```bash
cd istio-*
```

Add istioctl to PATH:

```bash
export PATH=$PWD/bin:$PATH
```

Verify:

```bash
istioctl version
```

Install Istio:

```bash
istioctl install --set profile=demo -y
```

Verify installation:

```bash
kubectl get pods -n istio-system
```

Expected pods:

- istiod
- istio-ingressgateway

---

# 3. Create Namespace

## namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: onlineshop-ns
```

Apply:

```bash
kubectl apply -f namespace.yaml
```

---

# 4. Enable Istio Sidecar Injection

Enable automatic Envoy sidecar injection:

```bash
kubectl label namespace onlineshop-ns istio-injection=enabled
```

Verify:

```bash
kubectl get ns --show-labels
```

---

# 5. Create Deployment

## deployment.yaml

> IMPORTANT:
> Ensure your application actually listens on the container port you specify.

Example if app runs on port 3000:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: onlineshop-deployment
  namespace: onlineshop-ns
  labels:
    app: onlineshop

spec:
  replicas: 2

  selector:
    matchLabels:
      app: onlineshop

  template:
    metadata:
      labels:
        app: onlineshop

    spec:
      containers:
        - name: onlineshop-pod
          image: zeeshankanuga/onineshop:latest

          ports:
            - containerPort: 3000
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

---

# 6. Create Kubernetes Service

## service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: onlineshop-svc
  namespace: onlineshop-ns
  labels:
    app: onlineshop

spec:
  selector:
    app: onlineshop

  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000

  type: ClusterIP
```

Apply:

```bash
kubectl apply -f service.yaml
```

---

# 7. Verify Application

Check pods:

```bash
kubectl get pods -n onlineshop-ns
```

Expected:

```text
2/2 Running
```

This means:

- app container
- istio-proxy sidecar

Verify service endpoints:

```bash
kubectl get endpoints -n onlineshop-ns
```

---

# 8. Test Application Without Istio

Port-forward service:

```bash
kubectl port-forward svc/onlineshop-svc -n onlineshop-ns 9000:80
```

Open:

```text
http://localhost:9000
```

If this fails:

- your app is not running correctly
- OR app port is incorrect

---

# 9. Create Istio Gateway

## gateway.yaml

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: onlineshop-gateway
  namespace: onlineshop-ns

spec:
  selector:
    istio: ingressgateway

  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP

      hosts:
        - "*"
```

Apply:

```bash
kubectl apply -f gateway.yaml
```

---

# 10. Create VirtualService

## virtualservice.yaml

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: onlineshop-vs
  namespace: onlineshop-ns

spec:
  hosts:
    - "*"

  gateways:
    - onlineshop-gateway

  http:
    - route:
        - destination:
            host: onlineshop-svc.onlineshop-ns.svc.cluster.local

            port:
              number: 80
```

Apply:

```bash
kubectl apply -f virtualservice.yaml
```

---

# 11. Access Application Through Istio

Port-forward Istio ingress gateway:

```bash
kubectl port-forward svc/istio-ingressgateway -n istio-system 3000:80
```

Open in browser:

```text
http://localhost:3000
```

---

# 12. Verify Istio Configuration

Check gateway:

```bash
kubectl get gateway -n onlineshop-ns
```

Check VirtualService:

```bash
kubectl get virtualservice -n onlineshop-ns
```

Check proxy status:

```bash
istioctl proxy-status
```

Analyze configuration:

```bash
istioctl analyze
```

---

# 13. Debugging

## Check pod logs

```bash
kubectl logs -n onlineshop-ns deployment/onlineshop-deployment
```

---

## Verify sidecar injection

```bash
kubectl describe pod <pod-name> -n onlineshop-ns
```

Expected container list:

```text
onlineshop-pod
istio-proxy
```

---

## Verify service endpoints

```bash
kubectl get endpoints -n onlineshop-ns
```

---

## Verify application listening port

```bash
kubectl exec -it -n onlineshop-ns <pod-name> -- netstat -tulpn
```

OR

```bash
kubectl exec -it -n onlineshop-ns <pod-name> -- ss -tulpn
```

---

# Common Issues

## 1. Pods show 1/1 instead of 2/2

Cause:
- Istio sidecar injection not enabled

Fix:

```bash
kubectl label namespace onlineshop-ns istio-injection=enabled
kubectl rollout restart deployment onlineshop-deployment -n onlineshop-ns
```

---

## 2. Service has no endpoints

Cause:
- Service selector mismatch

Verify labels:

```yaml
labels:
  app: onlineshop
```

and:

```yaml
selector:
  app: onlineshop
```

must match.

---

## 3. Application not accessible

Cause:
- Wrong container port

Example:

Node.js apps often run on:
- 3000
- 5000
- 8080

Update:

```yaml
targetPort: 3000
```

accordingly.

---

# Cleanup

Delete resources:

```bash
kubectl delete -f .
```

Delete cluster:

```bash
kind delete cluster --name kind-zeeshan
```

---

# Useful Commands

## Check all resources

```bash
kubectl get all -n onlineshop-ns
```

---

## Check Istio resources

```bash
kubectl get gateway,virtualservice -n onlineshop-ns
```

---

## Check ingress gateway

```bash
kubectl get svc istio-ingressgateway -n istio-system
```

---

# Final Result

Your application is now running with:

- Kubernetes
- Istio Service Mesh
- Envoy Sidecars
- Istio Gateway
- VirtualService Routing
- Ingress Traffic Management
