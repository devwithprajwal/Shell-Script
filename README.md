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
