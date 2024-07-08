#!/bin/bash

set -e

# Variables
PROJECT_ID="flowing-digit-394109"
LOCATION="europe-west4"
ENVIRONMENT_NAME="composer-test"
ROLE_NAME="custom_viewer"
EMAIL_ID="vaishnavi2000m@gmail.com"

# Authenticate and configure gcloud
gcloud auth login
gcloud config set project ${PROJECT_ID}

# Get the Airflow URI
AIRFLOW_URI=$(gcloud composer environments describe ${ENVIRONMENT_NAME} --location ${LOCATION} --format "value(config.airflowUri)")

# Obtain an authentication token
TOKEN=$(gcloud auth print-access-token)

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq."
    exit
fi

# Check if the role already exists
EXISTING_ROLE=$(curl -s -X GET "${AIRFLOW_URI}/auth/fab/v1/roles?name=${ROLE_NAME}" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "Existing Role Response: $EXISTING_ROLE"

if [[ $(echo $EXISTING_ROLE | jq '.total_entries') -gt 0 ]]; then
  echo "Role ${ROLE_NAME} already exists."
else
  # Create the role
  CREATE_ROLE_RESPONSE=$(curl -s -X POST "${AIRFLOW_URI}/auth/fab/v1/roles" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"name": "'${ROLE_NAME}'"}')

  echo "Create Role Response: $CREATE_ROLE_RESPONSE"
fi

# Define permissions
PERMISSIONS=(
  '{"action": "can_read", "resource": "DagModelView"}'
  '{"action": "can_read", "resource": "TaskInstanceModelView"}'
  '{"action": "can_read", "resource": "LogModelView"}'
)

# Assign permissions to the role
for perm in "${PERMISSIONS[@]}"; do
  ASSIGN_PERM_RESPONSE=$(curl -s -X POST "${AIRFLOW_URI}/auth/fab/v1/roles/${ROLE_NAME}/permissions" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${perm}")

  echo "Assign Permission Response: $ASSIGN_PERM_RESPONSE"
done

# Get the user ID by email
USER_RESPONSE=$(curl -s -X GET "${AIRFLOW_URI}/auth/fab/v1/users?email=${USER_EMAIL}" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "User Response: $USER_RESPONSE"

USER_ID=$(echo $USER_RESPONSE | jq -r '.users[0].id')

if [ -z "$USER_ID" ]; then
  echo "User ${USER_EMAIL} does not exist."
else
  # Assign the role to the user
  ASSIGN_ROLE_RESPONSE=$(curl -s -X PATCH "${AIRFLOW_URI}/auth/fab/v1/users/${USER_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"roles": ["'${ROLE_NAME}'"]}')

  echo "Assign Role Response: $ASSIGN_ROLE_RESPONSE"
fi