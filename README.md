# Capstone Application - DevOps Project

This repository contains the containerized web application and CI/CD pipeline for the DevOps Capstone project.

## Features

- Professional responsive website
- Dockerized Nginx application
- Automated CI/CD with GitHub Actions
- Kubernetes deployment manifests
- Rolling updates with zero downtime

## Architecture

```
GitHub Push → GitHub Actions → Docker Build → Docker Hub → K3s Deployment → Public Access
```

## Prerequisites

- Docker Hub account
- GitHub repository
- K3s cluster (from capstone-infra)
- GitHub Actions secrets configured

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/capstone-app.git
cd capstone-app
```

### 2. Test locally with Docker
```bash
cd app
docker build -t capstone-app .
docker run -p 8080:80 capstone-app
```

Visit: http://localhost:8080

### 3. Configure GitHub Secrets

Go to Settings → Secrets and variables → Actions, add:

- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Docker Hub access token
- `K3S_HOST`: EC2 public IP from Terraform output
- `SSH_PRIVATE_KEY`: Your SSH private key (matching the public key in Terraform)

### 4. Update Kubernetes manifests

Edit `kubernetes/deployment.yaml`:
```yaml
image: YOUR_DOCKERHUB_USERNAME/capstone-app:latest
```

### 5. Initial deployment to K3s

SSH to your K3s instance:
```bash
ssh ubuntu@<EC2_IP>
```

Create namespace and deploy:
```bash
kubectl create namespace capstone

# Apply manifests
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: capstone-app
  namespace: capstone
spec:
  replicas: 2
  selector:
    matchLabels:
      app: capstone-app
  template:
    metadata:
      labels:
        app: capstone-app
    spec:
      containers:
      - name: capstone-app
        image: YOUR_DOCKERHUB_USERNAME/capstone-app:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: capstone-app
  namespace: capstone
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: capstone-app
EOF
```

### 6. Access your application

Visit: `http://<EC2_IP>:30080`

## CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Build**: Creates Docker image from app/
2. **Push**: Uploads to Docker Hub with tags (latest + commit SHA)
3. **Deploy**: Updates K3s deployment via SSH
4. **Verify**: Checks rollout status

Triggered on push to `main` or `master` branch.

## Project Structure

```
capstone-app/
├── app/
│   ├── Dockerfile          # Container definition
│   ├── index.html          # Main website
│   └── style.css           # Styling
├── kubernetes/
│   ├── deployment.yaml     # K8s deployment
│   └── service.yaml        # K8s service (NodePort)
├── .github/
│   └── workflows/
│       └── ci-cd.yaml      # GitHub Actions pipeline
└── README.md               # This file
```

## Kubernetes Commands

Check deployment status:
```bash
kubectl get all -n capstone
kubectl get pods -n capstone
kubectl logs -f deployment/capstone-app -n capstone
```

Scale deployment:
```bash
kubectl scale deployment/capstone-app --replicas=3 -n capstone
```

Update image manually:
```bash
kubectl set image deployment/capstone-app \
  capstone-app=YOUR_USERNAME/capstone-app:latest \
  -n capstone
```

Rollback deployment:
```bash
kubectl rollout undo deployment/capstone-app -n capstone
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n capstone
kubectl logs <pod-name> -n capstone
```

### Image pull errors
- Verify Docker Hub credentials
- Check image name in deployment.yaml
- Ensure image exists: `docker pull YOUR_USERNAME/capstone-app:latest`

### Service not accessible
```bash
# Check service
kubectl get svc -n capstone

# Check NodePort
kubectl get svc capstone-app -n capstone -o jsonpath='{.spec.ports[0].nodePort}'

# Verify security group allows port 30080
```

### GitHub Actions failing
- Check secrets are set correctly
- Verify SSH key has no passphrase
- Check K3s host is reachable
- Review workflow logs in Actions tab

## Manual Deployment Steps

If you need to deploy without CI/CD:

```bash
# Build and push
cd app
docker build -t YOUR_USERNAME/capstone-app:v1.0 .
docker push YOUR_USERNAME/capstone-app:v1.0

# Deploy to K3s
ssh ubuntu@<EC2_IP>
kubectl set image deployment/capstone-app \
  capstone-app=YOUR_USERNAME/capstone-app:v1.0 \
  -n capstone
```

## Monitoring

View real-time logs:
```bash
kubectl logs -f -l app=capstone-app -n capstone
```

Watch pod status:
```bash
watch kubectl get pods -n capstone
```

## Cleanup

Delete deployment:
```bash
kubectl delete namespace capstone
```

## Next Steps

- Add health checks and readiness probes
- Implement Horizontal Pod Autoscaler
- Add Ingress controller for domain mapping
- Set up monitoring with Prometheus/Grafana
- Implement blue-green deployments

## License

MIT License - Educational Project
