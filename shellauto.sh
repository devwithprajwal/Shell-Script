#!/bin/bash

# Set variables
AKS_CLUSTER_NAME="aksprajwal"
AKS_RESOURCE_GROUP="prajwal-rg"
LOG_DIR="./pod"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Connect to AKS cluster
echo "Connecting to AKS cluster..."

az aks get-credentials --resource-group "$AKS_RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME"


if [ $? -ne 0 ]; then
    echo "Failed to connect to AKS cluster. Exiting."
    exit 1
fi

echo "Connected to AKS cluster."

# Get all namespaces
echo "Available namespaces:"
kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'

# Prompt user for namespace
read -p "    Please enter the namespace you want to process: " SELECTED_NAMESPACE
if [ -z "$SELECTED_NAMESPACE" ]; then
    echo "No namespace selected. Exiting."
    exit 1
fi

echo "Selected namespace: $SELECTED_NAMESPACE"

# Get all deployments in the selected namespace
echo "Fetching deployments in namespace: $SELECTED_NAMESPACE..."
DEPLOYMENTS=$(kubectl get deployments -n "$SELECTED_NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | tr -d '\r')
if [ -z "$DEPLOYMENTS" ]; then
    echo "No deployments found in namespace: $SELECTED_NAMESPACE. Exiting."
    exit 1
fi

echo "Deployments found:"
echo "$DEPLOYMENTS"

# Loop through deployments to get pods and collect logs
for deployment in $DEPLOYMENTS; do
    echo "Processing deployment: $deployment in namespace: $SELECTED_NAMESPACE"

    # Get pods for the deployment
    PODS=$(kubectl get pods -n "$SELECTED_NAMESPACE" -l "app=$deployment" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | tr -d '\r')
    if [ -z "$PODS" ]; then
        echo "No pods found for deployment: $deployment. Skipping."
        continue
    fi

    # Loop through pods and collect logs
    for pod in $PODS; do
        echo "Collecting logs for pod: $pod"
        LOG_FILE="$LOG_DIR/${pod}.txt"
        kubectl logs -n "$SELECTED_NAMESPACE" "$pod" > "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo "Logs for pod $pod saved to $LOG_FILE"
        else
            echo "Failed to collect logs for pod $pod"
        fi
    done
done

echo "Log collection completed. Logs saved to $LOG_DIR."
