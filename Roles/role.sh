#!/bin/bash

set -e

# Variables
PROJECT_ID="flowing-digit-394109"
LOCATION="europe-west4"
ENVIRONMENT_NAME="composer-test"
ROLE_NAME="custom_viewer"
EMAIL_ID="vaishnavi2000m@gmail.com"

#!/bin/bash

# Get the Airflow URI
AIRFLOW_URI="https://a864faeb25904898bdabfa7b2aa0a8b6-dot-europe-west4.composer.googleusercontent.com/auth/fab/v1"

# Obtain an authentication token
TOKEN="ya29.c.c0AY_VpZi3ymy2sYA2PSBsU8XAdGRMXgkIWkIGrbrwUEal4q5IDyhh7HG-hic5OIebVuE8pHEEQ18rw7LXKZ-aksULNqZ2OwQdht2DMF3VrkF6nTJBidxj88yZ3QC7Kos1kJKf7uSUyGNQ3vMjweQ2SZauL86d5FgpaiLGuUCV5yvYU-NEQ2CPi5RMrhUH5Rznf1VwIUIXhnM5hr7IVu75wDY6h02VYHmzP5UiPWkfPaNOzkP3RqU4Z7AlzP4Ek_roJ6p93XveTnYhm-NHCNxTvOfAb0urr0SwAnf4l0Z7DLvL8RL32_w5HwdwcVkwmi0Gc95a-qMqlW2jgyspuTgaVlEbE3dOssG7tkn9Zt8EhKbMB1ozpL8xvl_BG5-nta2ZbFesTQG399Cr-vmZFy8OtmxjXzR9xOe6kexkS3i4jOJinM4acM7Z0Jq0odkUvj1lS_5mxmoUtedRgqwcV9Uf5QJj8fvxsbrWYRqZoej2lU8e1up6Jc2BOlI9V1t5iSr7OvO7hFv3R5oxnhgQhZUzi6yfezxwc73tte_s6yJ4QJFI_74gBtoV52IWvYYWSw6S1xehjtV9m6mY6o3kUuve1jfi0rVX6larxJYu4mIRwvkh12dqm8Onhzcr7Wn9RvBsqOv0q4ep-iv3xWbz9eJy2isSsy0s6WZIf0J9g9qW9uQcsawd2JJJRMFBf81-b46iYQd2-pMun15mwfJqd298q-2_7X6J5B1QFMzO77Wo_ngvhlSemhnUdMYvz3ye5phoMBQul9XIStFzkB9k3mO8f10MZng0-g_malfemIi4mgj88eW4Xdp47j6oRrBsuxRUWqgU5I_BvfUSZVXhrUv_9V0O0F85aqMRf041QXqhf9xxg0t-pzsYcza9W-3Yl9Fd0YtM-MBc7BqqbeMjirzO1_4xcMcRrWoZM6cxISMVsIFjhhwhoXxs_4Q8VXRg-sVskuY-fkJY6kOipk815_5rypRqf1a_jqYlB8enlQjSvYvBirBhSfJm11M"

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