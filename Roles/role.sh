#!/bin/bash

set -e

# Variables
PROJECT_ID="flowing-digit-394109"
LOCATION="europe-west4"
ENVIRONMENT_NAME="composer-test"
ROLE_NAME="custom_viewer"
EMAIL_ID="vaishnavi2000m@gmail.com"

#!/bin/bash

gcloud auth login

gcloud config set account vaishnavi2000m@gmail.com

# Set project
gcloud config set project ${PROJECT_ID}

# Get the Airflow URI
AIRFLOW_URI=$(gcloud composer environments describe ${ENVIRONMENT_NAME} --location ${LOCATION} --format "value(config.airflowUri)")

# Obtain an authentication token
TOKEN=$(gcloud auth print-access-token)

# Create custom role
ROLE_NAME="custom_viewer"
if curl -s -X GET "${AIRFLOW_URI}/api/v1/roles?name=${ROLE_NAME}" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" | jq '.length' | grep -q 0; then
  echo "Role ${ROLE_NAME} already exists, skipping creation."
else
  curl -X POST "${AIRFLOW_URI}/api/v1/roles" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"name": "'${ROLE_NAME}'"}'
  echo "Role ${ROLE_NAME} created successfully!"
fi

PERMISSIONS=(
  '{"action": "can_read", "resource": "DagModelView"}'
  '{"action": "can_read", "resource": "TaskInstanceModelView"}'
  '{"action": "can_read", "resource": "LogModelView"}'
)

# Assign permissions to the custom role
for perm in "${PERMISSIONS[@]}"; do
  curl -X POST "${AIRFLOW_URI}/api/v1/roles/${ROLE_NAME}/permissions" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${perm}"
done

# Get the user by email ID

if curl -s -X GET "${AIRFLOW_URI}/api/v1/users?email=${USER_EMAIL}" -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" | jq '.length' | grep -q 0; then
  # Assign the custom role to the user
  curl -X PATCH "${AIRFLOW_URI}/api/v1/users/${USER_EMAIL}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"roles": ["'${ROLE_NAME}'"]}'
else
  echo "User ${USER_EMAIL} does not exist, skipping assignment."
fi