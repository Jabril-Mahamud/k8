# Kubernetes Multi-Tier App

A full-stack application demonstrating Kubernetes deployment with Next.js frontend, Go backend, and PostgreSQL database.

## 🏗️ Architecture

```md
Frontend (Next.js) → Backend (Go) → Database (PostgreSQL)
```

- **Frontend**: Next.js 16 with React 19, static export served by nginx
- **Backend**: Go REST API with PostgreSQL driver
- **Database**: PostgreSQL 15 for data persistence
- **Platform**: Kubernetes (via kind for local development)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) - For building container images
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI

### Install Prerequisites

**macOS (Homebrew):**

```bash
brew install docker kind kubectl
```

**Linux:**

```bash
# Docker - follow official docs
# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd k8-study
```

### 2. Run the Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

The setup script will:

- ✅ Check prerequisites
- ✅ Create a kind cluster named "learning"
- ✅ Build Docker images for frontend and backend
- ✅ Load images into the kind cluster
- ✅ Deploy all Kubernetes resources in the correct order
- ✅ Wait for all pods to be ready

### 3. Access the Application

After setup completes, start port forwarding:

```bash
kubectl port-forward -n dev svc/frontend 8080:80
```

Open your browser to: **<http://localhost:8080>**

You should see the dashboard with:

- Database connection status
- List of users from the database
- Quick stats

## 📁 Project Structure

```md
.
├── backend/                    # Go REST API
│   ├── main.go                # Application code
│   ├── Dockerfile             # Backend container
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   └── backend-config.yaml
├── frontend/                   # Next.js application
│   ├── app/                   # Next.js app directory
│   ├── Dockerfile             # Frontend container
│   ├── nginx.conf             # Nginx configuration
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
├── db/                        # Database manifests
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── postgres-secret.yaml
├── setup.sh                   # Automated setup script
└── teardown.sh               # Cleanup script
```

## 🛠️ Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Create kind cluster

```bash
kind create cluster --name learning
```

### 2. Create namespace

```bash
kubectl create namespace dev
```

### 3. Build and load images

```bash
# Build backend
cd backend
docker build -t backend-go:v1 .
cd ..

# Build frontend
cd frontend
docker build -t frontend-nextjs:v1 .
cd ..

# Load into kind
kind load docker-image backend-go:v1 --name learning
kind load docker-image frontend-nextjs:v1 --name learning
```

### 4. Apply manifests in order

```bash
# Secrets and ConfigMaps
kubectl apply -f db/postgres-secret.yaml
kubectl apply -f backend/backend-config.yaml

# Database
kubectl apply -f db/postgres-deployment.yaml
kubectl apply -f db/postgres-service.yaml

# Backend
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml

# Frontend
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml
```

### 5. Wait for pods

```bash
kubectl wait --for=condition=ready pod -l app=postgres -n dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=backend -n dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=frontend -n dev --timeout=120s
```

## 🔍 Useful Commands

### View Resources

```bash
# All pods in the dev namespace
kubectl get pods -n dev

# All services
kubectl get svc -n dev

# Detailed pod information
kubectl describe pod <pod-name> -n dev
```

### View Logs

```bash
# Backend logs
kubectl logs -n dev deployment/backend

# Frontend logs
kubectl logs -n dev deployment/frontend

# Database logs
kubectl logs -n dev deployment/postgres

# Follow logs in real-time
kubectl logs -n dev deployment/backend -f
```

### Debug

```bash
# Get a shell in a pod
kubectl exec -n dev deployment/frontend -it -- sh

# Test backend connectivity from frontend
kubectl exec -n dev deployment/frontend -it -- wget -O- http://backend/api/users

# Test database connectivity
kubectl exec -n dev deployment/backend -it -- wget -O- http://localhost:3000/api/test-db
```

### Scale Deployments

```bash
# Scale backend to 3 replicas
kubectl scale deployment backend -n dev --replicas=3

# Scale frontend to 1 replica
kubectl scale deployment frontend -n dev --replicas=1
```

## 🗑️ Cleanup

### Quick Cleanup (Recommended)

```bash
chmod +x teardown.sh
./teardown.sh
```

### Manual Cleanup

```bash
# Delete namespace (removes all resources)
kubectl delete namespace dev

# Delete kind cluster
kind delete cluster --name learning
```

## 🐛 Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n dev

# Check pod events
kubectl describe pod <pod-name> -n dev

# Check logs
kubectl logs -n dev <pod-name>
```

### Images not found

Make sure images are loaded into kind:

```bash
# Check images in kind
docker exec -it learning-control-plane crictl images

# Reload images
kind load docker-image backend-go:v1 --name learning
kind load docker-image frontend-nextjs:v1 --name learning
```

### Can't access the application

1. Check if port-forward is running
2. Verify all pods are in `Running` state
3. Test backend directly:

   ```bash
   kubectl exec -n dev deployment/frontend -it -- wget -O- http://backend/api/users
   ```

### Database connection issues

```bash
# Check if postgres is running
kubectl get pods -n dev -l app=postgres

# Check backend can reach database
kubectl exec -n dev deployment/backend -it -- ping postgres

# Check backend logs for connection errors
kubectl logs -n dev deployment/backend
```

## 🎓 Learning Resources

This project demonstrates:

- **Multi-tier application architecture** on Kubernetes
- **Service discovery** using Kubernetes DNS
- **ConfigMaps and Secrets** for configuration management
- **Deployments** with multiple replicas
- **Services** (ClusterIP and NodePort)
- **Docker multi-stage builds** for optimized images
- **kind** for local Kubernetes development

## 📝 API Endpoints

- `GET /health` - Health check endpoint
- `GET /api/test-db` - Test database connection
- `GET /api/users` - Fetch all users from database

## 🔐 Default Credentials

Database credentials (for local development only):

- Username: `myuser`
- Password: `mypassword`
- Database: `myapp`

**⚠️ Never use these credentials in production!**

## 🤝 Contributing

Feel free to fork this project and submit pull requests!

## 📄 License

This project is for educational purposes.
