#!/bin/bash
export PASS=$(cat pass.txt)
GITLAB_URL="https://gitlab.com/dtiven13"
TOKEN="$PASS"
PROJECT_ID="82751713"
PROJECT_NAME="test6"
NAMESPACE_ID="1"

echo "Deleting project..."
curl -s --request DELETE \
  --header "PRIVATE-TOKEN: $TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID"

sleep 10

echo "Creating project..."
curl -s --request POST \
  --header "PRIVATE-TOKEN: $TOKEN" \
  --data "name=$PROJECT_NAME" \
  --data "namespace_id=$NAMESPACE_ID" \
  "$GITLAB_URL/api/v4/projects"
