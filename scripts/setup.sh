#!/bin/bash

# Kubernetes Multi-Tier App Setup Script
# This script automates the deployment of the Next.js + Go + PostgreSQL stack on kind

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="learning"
NAMESPACE="dev"
BACKEND_IMAGE="backend-go:v1"
FRONTEND_IMAGE="frontend-nextjs:v1"

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."

    local missing=0

    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed"
        missing=1
    else
        print_success "docker found"
    fi

    if ! command -v kind &> /dev/null; then
        print_error "kind is not installed"
        echo "  Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        missing=1
    else
        print_success "kind found"
    fi

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        echo "  Install from: https://kubernetes.io/docs/tasks/tools/"
        missing=1
    else
        print_success "kubectl found"
    fi

    if [ $missing -eq 1 ]; then
        print_error "Please install missing prerequisites and try again"
        exit 1
    fi

    echo
}

# Create or verify kind cluster
setup_cluster() {
    print_step "Setting up kind cluster..."

    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "Cluster '${CLUSTER_NAME}' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Deleting existing cluster..."
            kind delete cluster --name "${CLUSTER_NAME}"
            print_success "Cluster deleted"
        else
            print_warning "Using existing cluster"
            return
        fi
    fi

    print_step "Creating kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "${CLUSTER_NAME}"
    print_success "Cluster created"

    # Wait a moment for cluster to be fully ready
    sleep 3
    echo
}

# Create namespace
create_namespace() {
    print_step "Creating namespace '${NAMESPACE}'..."

    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        print_warning "Namespace '${NAMESPACE}' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Deleting existing namespace..."
            kubectl delete namespace "${NAMESPACE}"
            print_success "Namespace deleted"

            # Wait for namespace to be fully deleted
            print_step "Waiting for namespace to be deleted..."
            while kubectl get namespace "${NAMESPACE}" &> /dev/null; do
                sleep 1
            done
        else
            print_warning "Using existing namespace"
            echo
            return
        fi
    fi

    kubectl create namespace "${NAMESPACE}"
    print_success "Namespace '${NAMESPACE}' created"
    echo
}

# Build Docker images
build_images() {
    print_step "Building Docker images..."

    # Build backend
    print_step "Building backend image..."
    cd backend
    docker build -t "${BACKEND_IMAGE}" .
    cd ..
    print_success "Backend image built: ${BACKEND_IMAGE}"

    # Build frontend
    print_step "Building frontend image..."
    cd frontend
    docker build -t "${FRONTEND_IMAGE}" .
    cd ..
    print_success "Frontend image built: ${FRONTEND_IMAGE}"

    echo
}

# Load images into kind
load_images() {
    print_step "Loading images into kind cluster..."

    kind load docker-image "${BACKEND_IMAGE}" --name "${CLUSTER_NAME}"
    print_success "Backend image loaded"

    kind load docker-image "${FRONTEND_IMAGE}" --name "${CLUSTER_NAME}"
    print_success "Frontend image loaded"

    echo
}

# Apply Kubernetes manifests
apply_manifests() {
    print_step "Applying Kubernetes manifests..."

    # 1. Secrets and ConfigMaps
    print_step "Applying secrets and configmaps..."
    kubectl apply -f db/postgres-secret.yaml
    kubectl apply -f backend/backend-config.yaml
    print_success "Secrets and configmaps applied"

    # 2. Database
    print_step "Deploying database..."
    kubectl apply -f db/postgres-deployment.yaml
    kubectl apply -f db/postgres-service.yaml
    print_success "Database deployed"

    # 3. Backend
    print_step "Deploying backend..."
    kubectl apply -f backend/backend-deployment.yaml
    kubectl apply -f backend/backend-service.yaml
    print_success "Backend deployed"

    # 4. Frontend
    print_step "Deploying frontend..."
    kubectl apply -f frontend/frontend-deployment.yaml
    kubectl apply -f frontend/frontend-service.yaml
    print_success "Frontend deployed"

    echo
}

# Wait for pods to be ready
wait_for_pods() {
    print_step "Waiting for pods to be ready..."

    echo "This may take a minute or two..."

    # Wait for postgres deployment to be ready
    kubectl rollout status deployment/postgres -n "${NAMESPACE}" --timeout=120s
    print_success "Database pod ready"

    # Wait for backend deployment to be ready
    kubectl rollout status deployment/backend -n "${NAMESPACE}" --timeout=120s
    print_success "Backend pods ready"

    # Wait for frontend deployment to be ready
    kubectl rollout status deployment/frontend -n "${NAMESPACE}" --timeout=120s
    print_success "Frontend pods ready"

    echo
}

# Show final status
show_status() {
    print_step "Deployment complete! Here's your cluster status:"
    echo

    kubectl get pods -n "${NAMESPACE}"
    echo
    kubectl get svc -n "${NAMESPACE}"
    echo

    print_success "All services are running!"
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${BLUE}To access your application:${NC}"
    echo
    echo "  1. Start port forwarding:"
    echo -e "     ${YELLOW}kubectl port-forward -n ${NAMESPACE} svc/frontend 8080:80${NC}"
    echo
    echo "  2. Open your browser to:"
    echo -e "     ${YELLOW}http://localhost:8080${NC}"
    echo
    echo -e "${BLUE}Useful commands:${NC}"
    echo
    echo "  View pods:"
    echo -e "     ${YELLOW}kubectl get pods -n ${NAMESPACE}${NC}"
    echo
    echo "  View logs:"
    echo -e "     ${YELLOW}kubectl logs -n ${NAMESPACE} deployment/backend${NC}"
    echo -e "     ${YELLOW}kubectl logs -n ${NAMESPACE} deployment/frontend${NC}"
    echo
    echo "  Delete everything:"
    echo -e "     ${YELLOW}kubectl delete namespace ${NAMESPACE}${NC}"
    echo
    echo "  Delete cluster:"
    echo -e "     ${YELLOW}kind delete cluster --name ${CLUSTER_NAME}${NC}"
    echo
}

# Main execution
main() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}   Kubernetes Multi-Tier App Setup${NC}"
    echo -e "${BLUE}   Next.js → Go → PostgreSQL${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    check_prerequisites
    setup_cluster
    create_namespace
    build_images
    load_images
    apply_manifests
    wait_for_pods
    show_status
}

# Run main function
main