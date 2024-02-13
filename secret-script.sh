#!/bin/bash

# Check if kubeseal command exists
if ! command -v kubeseal &> /dev/null; then
    echo "Error: kubeseal command not found. Please make sure kubeseal is installed and in your PATH." >&2
    exit 1
fi

# Function to create a sealed secret from key-value pairs
create_sealed_secret() {
    local secret_name="$1"
    local namespace="$2"
    local secret_data="$3"
    
    # Construct Kubernetes Secret YAML
    cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $secret_name
  namespace: $namespace
type: Opaque
data:
$secret_data
EOF
}

# Check if arguments are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 [-f <file_path>] [<key1=value1> <key2=value2> ...]" >&2
    exit 1
fi

# Initialize variables
secret_name="my-secret"
namespace="default"
secret_data=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -f|--file)
            file_path="$2"
            if [ ! -f "$file_path" ]; then
                echo "Error: File $file_path not found." >&2
                exit 1
            fi
            secret_data=$(cat "$file_path")
            shift 2
            ;;
        local)
            # Handle local values differently
            echo "Handling local value: $2"
            # You can add your logic here to handle local values differently
            shift 2
            ;;
        *)
            key_value=(${key//=/ })
            secret_data+="  ${key_value[0]}: ${key_value[1]}\n"
            shift
            ;;
    esac
done

# Seal the secret
echo "Sealing the secret..."
create_sealed_secret "$secret_name" "$namespace" "$secret_data" | kubeseal --format=yaml

