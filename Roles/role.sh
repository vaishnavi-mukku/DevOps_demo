#!/bin/bash

# Set project ID and service account key
export PROJECT_ID="${{ secrets.GCP_PROJECT_ID }}"
export SERVICE_ACCOUNT_KEY="${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}"

# Install jq
sudo apt-get install -y jq

# Authenticate with Google Cloud
echo "${SERVICE_ACCOUNT_KEY}" > key.json
gcloud auth activate-service-account --key-file=key.json

# Set project
gcloud config set project ${PROJECT_ID}

# Function to log API responses
log_response() {
  echo "Response:"
  echo "$1" | jq .
}

# Function to call Airflow API and log response
call_airflow_api() {
  local url=$1
  local method=$2
  local data=$3

  response=$(curl -s -X ${method} -H "Content-Type: application/json" -d "${data}" ${url})
  log_response "${response}"

  if [[ $(echo "${response}" | jq -r '.status_code') != "200" ]]; then
    echo "Error: API call failed with response: ${response}"
    exit 1
  fi
}

# Create custom role
role_url="https://302b466c397544e5b96832b0c3dce458-dot-europe-west4.composer.googleusercontent.com/auth/fab/v1/roles"
role_data='{"name": "custom_viewer"}'
call_airflow_api "${role_url}" "POST" "${role_data}"

# Assign permissions to role
permission_url="https://302b466c397544e5b96832b0c3dce458-dot-europe-west4.composer.googleusercontent.com/auth/fab/v1/permissions"
permission_data='{"role_name": "custom_viewer", "permission": "can_read", "view_menu": "Dag"}'
call_airflow_api "${permission_url}" "POST" "${permission_data}"

# Assign role to user
user_role_url="https://302b466c397544e5b96832b0c3dce458-dot-europe-west4.composer.googleusercontent.com/auth/fab/v1/users"
user_role_data='{"username": "your_user", "role": "custom_viewer"}'
call_airflow_api "${user_role_url}" "POST" "${user_role_data}"

echo "Custom role created and assigned successfully!"
