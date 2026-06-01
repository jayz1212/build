#!/bin/bash

# GitLab Project Reset Script (Fixed with jq)
# Deletes a GitLab project and recreates it from scratch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
PROJECT_ID="${1:-}"
PROJECT_NAME="${2:-}"
PROJECT_VISIBILITY="${3:-private}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed"
        echo "Install it with: apt-get install jq or brew install jq"
        exit 1
    fi
}

# Function to validate inputs
validate_inputs() {
    if [ -z "$GITLAB_TOKEN" ]; then
        print_error "GITLAB_TOKEN environment variable is not set"
        echo "Set it with: export GITLAB_TOKEN=glpat-xxxxxxxxxxxxx"
        exit 1
    fi

    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID is required"
        echo "Usage: $0 PROJECT_ID [PROJECT_NAME] [VISIBILITY]"
        exit 1
    fi

    # Validate PROJECT_ID is numeric
    if ! [[ "$PROJECT_ID" =~ ^[0-9]+$ ]]; then
        print_error "PROJECT_ID must be numeric"
        exit 1
    fi
}

# Function to get project details
get_project_info() {
    print_status "Fetching project information..."
    
    PROJECT_INFO=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID")
    
    # Check for errors using jq
    if echo "$PROJECT_INFO" | jq -e '.message' &>/dev/null; then
        ERROR_MSG=$(echo "$PROJECT_INFO" | jq -r '.message')
        print_error "Failed to fetch project: $ERROR_MSG"
        exit 1
    fi
    
    # Extract project details using jq
    CURRENT_NAME=$(echo "$PROJECT_INFO" | jq -r '.name')
    CURRENT_VISIBILITY=$(echo "$PROJECT_INFO" | jq -r '.visibility')
    CURRENT_DESCRIPTION=$(echo "$PROJECT_INFO" | jq -r '.description // empty')
    NAMESPACE_ID=$(echo "$PROJECT_INFO" | jq -r '.namespace.id')
    
    if [ "$CURRENT_NAME" = "null" ] || [ -z "$CURRENT_NAME" ]; then
        print_error "Could not find project with ID: $PROJECT_ID"
        exit 1
    fi
    
    print_success "Project found: $CURRENT_NAME"
}

# Function to confirm deletion
confirm_deletion() {
    print_warning "About to delete project: $CURRENT_NAME (ID: $PROJECT_ID)"
    print_warning "This action cannot be undone!"
    echo ""
    read -p "Type the project name '$CURRENT_NAME' to confirm deletion: " confirmation
    
    if [ "$confirmation" != "$CURRENT_NAME" ]; then
        print_error "Confirmation failed. Deletion cancelled."
        exit 1
    fi
}

# Function to delete project
delete_project() {
    print_status "Deleting project..."
    
    HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/delete_response.json \
        -X DELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID")
    
    DELETE_RESPONSE=$(cat /tmp/delete_response.json)
    
    # 202 Accepted is success for deletion (async processing)
    if [ "$HTTP_CODE" != "202" ] && [ "$HTTP_CODE" != "204" ]; then
        if echo "$DELETE_RESPONSE" | jq -e '.message' &>/dev/null 2>/dev/null; then
            ERROR_MSG=$(echo "$DELETE_RESPONSE" | jq -r '.message')
            print_error "Failed to delete project (HTTP $HTTP_CODE): $ERROR_MSG"
        else
            print_error "Failed to delete project (HTTP $HTTP_CODE)"
        fi
        exit 1
    fi
    
    print_success "Project deletion initiated (HTTP $HTTP_CODE)"
    
    # Wait for deletion to complete
    print_status "Waiting for deletion to complete (max 30 seconds)..."
    for i in {1..30}; do
        sleep 1
        CHECK=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            "$GITLAB_URL/api/v4/projects/$PROJECT_ID" 2>/dev/null)
        
        if echo "$CHECK" | jq -e '.message' &>/dev/null 2>/dev/null; then
            print_success "Project deletion confirmed"
            return 0
        fi
    done
    
    print_warning "Project deletion may still be processing..."
}

# Function to recreate project
recreate_project() {
    local new_name="${PROJECT_NAME:-$CURRENT_NAME}"
    local new_visibility="${PROJECT_VISIBILITY:-$CURRENT_VISIBILITY}"
    
    print_status "Creating new project: $new_name"
    
    # Prepare JSON payload
    PAYLOAD=$(cat <<EOF
{
  "name": "$new_name",
  "visibility": "$new_visibility",
  "description": "$CURRENT_DESCRIPTION"
}
EOF
)
    
    CREATE_RESPONSE=$(curl -s -X POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "$PAYLOAD" \
        "$GITLAB_URL/api/v4/projects")
    
    # Check for errors
    if echo "$CREATE_RESPONSE" | jq -e '.message' &>/dev/null; then
        ERROR_MSG=$(echo "$CREATE_RESPONSE" | jq -r '.message')
        print_error "Failed to create project: $ERROR_MSG"
        exit 1
    fi
    
    NEW_PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')
    NEW_PROJECT_URL=$(echo "$CREATE_RESPONSE" | jq -r '.web_url')
    
    if [ "$NEW_PROJECT_ID" = "null" ] || [ -z "$NEW_PROJECT_ID" ]; then
        print_error "Could not extract new project ID from response"
        exit 1
    fi
    
    print_success "Project created successfully!"
    echo ""
    echo "New Project Details:"
    echo "  Name: $new_name"
    echo "  ID: $NEW_PROJECT_ID"
    echo "  Visibility: $new_visibility"
    echo "  URL: $NEW_PROJECT_URL"
}

# Main execution
main() {
    check_jq
    validate_inputs
    get_project_info
    confirm_deletion
    delete_project
    recreate_project
    
    echo ""
    print_success "Project reset completed!"
}

main "$@"
