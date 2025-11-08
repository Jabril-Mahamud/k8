#!/bin/bash

# Kubernetes Multi-Tier App Teardown Script
# This script cleans up all resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="learning"
NAMESPACE="dev"

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Kubernetes Multi-Tier App Teardown${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

echo "This will delete:"
echo "  - Namespace '${NAMESPACE}' and all resources inside it"
echo "  - kind cluster '${CLUSTER_NAME}'"
echo

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Teardown cancelled"
    exit 0
fi

# Delete namespace
if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    print_step "Deleting namespace '${NAMESPACE}'..."
    kubectl delete namespace "${NAMESPACE}"
    print_success "Namespace deleted"
else
    print_warning "Namespace '${NAMESPACE}' doesn't exist"
fi

# Delete kind cluster
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_step "Deleting kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "${CLUSTER_NAME}"
    print_success "Cluster deleted"
else
    print_warning "Cluster '${CLUSTER_NAME}' doesn't exist"
fi

echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🧹 Cleanup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo