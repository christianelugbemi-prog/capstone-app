#!/bin/bash
# Quick deployment script for capstone application

set -e

echo "==================================="
echo "Capstone App Deployment Script"
echo "==================================="

# Check if required variables are set
if [ -z "$DOCKERHUB_USERNAME" ]; then
    read -p "Enter your Docker Hub username: " DOCKERHUB_USERNAME
fi

if [ -z "$K3S_HOST" ]; then
    read -p "Enter your K3s host IP: " K3S_HOST
fi

echo ""
echo "Configuration:"
echo "  Docker Hub: $DOCKERHUB_USERNAME"
echo "  K3s Host: $K3S_HOST"
echo ""

# Build Docker image
echo "Step 1: Building Docker image..."
cd app
docker build -t $DOCKERHUB_USERNAME/capstone-app:latest .

# Push to Docker Hub
echo ""
echo "Step 2: Pushing to Docker Hub..."
docker push $DOCKERHUB_USERNAME/capstone-app:latest

# Deploy to K3s
echo ""
echo "Step 3: Deploying to K3s..."
cd ..

ssh ubuntu@$K3S_HOST << EOF
# Create namespace if not exists
kubectl create namespace capstone 2>/dev/null || true

# Apply deployment
kubectl apply -f - <<YAML
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
        image: $DOCKERHUB_USERNAME/capstone-app:latest
        imagePullPolicy: Always
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
YAML

# Wait for rollout
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/capstone-app -n capstone --timeout=5m

# Show status
echo ""
echo "Deployment Status:"
kubectl get all -n capstone
EOF

echo ""
echo "==================================="
echo "Deployment Complete!"
echo "==================================="
echo ""
echo "Access your application at:"
echo "  http://$K3S_HOST:30080"
echo ""
echo "Check status with:"
echo "  ssh ubuntu@$K3S_HOST 'kubectl get pods -n capstone'"
echo ""
