## AKS Pod Log Collector Script
This shell script automates the process of collecting **logs from all pods** under each deployment in a **specified namespace** within an **Azure Kubernetes Service (AKS) cluster**.

## ✅ What the script does:
- Connects to an existing AKS cluster using az aks get-credentials

- Lists all available Kubernetes namespaces

- Prompts the user to input a namespace to process

- Finds all deployments in the selected namespace

- For each deployment, identifies associated pods using the app label

- Retrieves logs for each pod and saves them to local .txt files in a pod/ directory

**Logs are stored locally under the ./pod/ directory, one file per pod.**

**This is helpful for debugging, auditing, or capturing real-time pod output without editing any YAML files or accessing each pod manually.**

## ⚙️ Workflow :

1. First step is to connect to the aks cluster and also create a new directory to store the pod details under pod.txt file.
   
```yaml
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
```
2. Trying to get inside a specific namespace to collect specific deployment details.

```yaml
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
```
3. Going inside a specific deployment to get a list of pods in it.  

```yaml
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
```
4. Collecting all the logs of the existing PODS of specific deployment and storing it in pod.txt file in "$LOG_DIR" directory.New pod details are overwritten in the existing pod file whenever the same script is run again.
```yaml
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
```   
