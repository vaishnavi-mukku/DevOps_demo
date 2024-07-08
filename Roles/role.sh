#!/bin/bash

# Replace with your Composer environment details
PROJECT_ID="flowing-digit-394109"
LOCATION="europe-west4"
ENVIRONMENT_NAME="composer-test"

# Airflow API endpoint for roles
AIRFLOW_API_BASE_URL="https://composer.googleapis.com/v1beta1/projects/${PROJECT_ID}/locations/${LOCATION}/environments/${ENVIRONMENT_NAME}/services/airflow/api/v1"

# Replace with your service account credentials
export SERVICE_ACCOUNT_KEY="${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}"

# Function to create a role
create_role() {
    local role_name="$1"
    local endpoint="${AIRFLOW_API_BASE_URL}/roles"
    local headers=(
        "-H" "Content-Type: application/json"
        "-H" "Authorization: Bearer $(gcloud auth application-default print-access-token)"
    )
    local data="{\"name\": \"${role_name}\"}"

    # Send POST request to create role
    response=$(curl -s -X POST "${endpoint}" "${headers[@]}" -d "${data}")

    # Check response for success or failure
    if [[ "$(echo "${response}" | jq -r '.status')" == "success" ]]; then
        echo "Role '${role_name}' created successfully!"
    else
        error_message=$(echo "${response}" | jq -r '.detail')
        echo "Failed to create role '${role_name}': ${error_message}"
    fi
}

# Example usage
role_name="custom_veiwer"
create_role "${role_name}"
