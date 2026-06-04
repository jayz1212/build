#!/bin/bash

# GitLab Project Delete & Recreate - All in One
# Usage: ./gitlab-reset.sh https://gitlab.com/dtiven13/test2

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get inputs
GITLAB_URL_INPUT="${1:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"

# If no URL provided, ask for it
if [ -z "$GITLAB_URL_INPUT" ]; then
    echo -e "${BLUE}=== GitLab Project Reset ===${NC}"
    echo ""
    read -p "Enter GitLab project URL (e.g., https://gitlab.com/user/project): " GITLAB_URL_INPUT
fi

# If no token, ask for it
if [ -z "$GITLAB_TOKEN" ]; then
    read -sp "Enter GitLab Personal Access Token (glpat-...): " GITLAB_TOKEN
    echo ""
fi

# Validate token is set
if [ -z "$GITLAB_TOKEN" ]; then
    print_error "Token is required"
    exit 1
fi

# Validate URL format
if [[ ! "$GITLAB_URL_INPUT" =~ ^https?:// ]]; then
    GITLAB_URL_INPUT="https://$GITLAB_URL_INPUT"
fi

# Extract GitLab instance and project path
GITLAB_INSTANCE=$(echo "$GITLAB_URL_INPUT" | sed 's|https://||' | sed 's|http://||' | cut -d'/' -f1)
PROJECT_PATH=$(echo "$GITLAB_URL_INPUT" | sed "s|.*$GITLAB_INSTANCE/||")

GITLAB_API="https://$GITLAB_INSTANCE/api/v4"

print_status "GitLab Instance: https://$GITLAB_INSTANCE"
print_status "Project Path: $PROJECT_PATH"
print_status "Fetching project ID..."

# Get project ID from path
PROJECT_RESPONSE=$(curl -s -w "\n%{http_code}" --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_API/projects/$(echo $PROJECT_PATH | sed 's|/|%2F|g')")

PROJECT_HTTP_CODE=$(echo "$PROJECT_RESPONSE" | tail -n1)
PROJECT_DATA=$(echo "$PROJECT_RESPONSE" | sed '$d')

PROJECT_EXISTS=true
if [[ "$PROJECT_HTTP_CODE" != "200" ]]; then
    PROJECT_EXISTS=false
    print_warning "Project not found (HTTP $PROJECT_HTTP_CODE) — skipping deletion, will create fresh"
fi

if $PROJECT_EXISTS; then
    PROJECT_ID=$(echo "$PROJECT_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['id'])")
    PROJECT_NAME=$(echo "$PROJECT_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name',''))")
    PROJECT_VISIBILITY=$(echo "$PROJECT_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('visibility','private'))")
    PROJECT_DESC=$(echo "$PROJECT_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('description','') or '')")

    if [ -z "$PROJECT_ID" ]; then
        print_error "Could not extract project ID"
        exit 1
    fi

    print_success "Project found: $PROJECT_NAME (ID: $PROJECT_ID)"
    echo ""
    print_status "Deleting project..."

    # Delete project
    DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_API/projects/$PROJECT_ID")

    HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
    DELETE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

    if [[ "$HTTP_CODE" != "202" && "$HTTP_CODE" != "204" ]]; then
        print_error "Failed to delete project (HTTP $HTTP_CODE)"
        echo "Response: $DELETE_BODY"
        exit 1
    fi

    print_success "Project deletion initiated (HTTP $HTTP_CODE)"

    # Wait for deletion
    print_status "Waiting for deletion to complete..."
    for i in {1..30}; do
        sleep 1
        CHECK=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            "$GITLAB_API/projects/$PROJECT_ID" 2>/dev/null)

        if echo "$CHECK" | grep -q '"message"'; then
            print_success "Project deletion confirmed"
            break
        fi

        if [ $i -eq 30 ]; then
            print_warning "Deletion may still be processing..."
        fi
    done
else
    # Project doesn't exist — derive name from the URL path
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    PROJECT_VISIBILITY="public"
    PROJECT_DESC=""
fi

echo ""
print_status "Creating new project: $PROJECT_NAME..."

# Recreate project
PAYLOAD="{\"name\":\"$PROJECT_NAME\",\"visibility\":\"$PROJECT_VISIBILITY\",\"description\":\"$PROJECT_DESC\"}"

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$PAYLOAD" \
    "$GITLAB_API/projects")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "201" ]]; then
    print_error "Failed to create project (HTTP $HTTP_CODE)"
    echo "Response: $CREATE_BODY"
    exit 1
fi

NEW_PROJECT_ID=$(echo "$CREATE_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['id'])")
NEW_PROJECT_URL=$(echo "$CREATE_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('web_url',''))")

echo ""
print_success "Project created successfully!"
echo ""
echo "New Project Details:"
echo "  Name: $PROJECT_NAME"
echo "  ID: $NEW_PROJECT_ID"
echo "  Visibility: $PROJECT_VISIBILITY"
echo "  URL: $NEW_PROJECT_URL"
echo ""
print_success "Reset completed!"
