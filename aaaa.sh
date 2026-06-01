#!/bin/bash

# GitLab Project Reset Script
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

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [PROJECT_ID] [PROJECT_NAME] [VISIBILITY]

Arguments:
  PROJECT_ID        - GitLab project ID (numeric ID from project settings)
  PROJECT_NAME      - Name for the recreated project (optional, defaults to original)
  VISIBILITY        - Project visibility: private, internal, or public (default: private)

Environment Variables:
  GITLAB_URL        - GitLab instance URL (default: https://gitlab.com)
  GITLAB_TOKEN      - GitLab personal access token (required)

Examples:
  $0 12345 my-project private
  GITLAB_TOKEN=glpat-xxx PROJECT_ID=12345 $0

Interactive mode (no arguments):
  $0

EOF
    exit 1
}

# Function to validate inputs
validate_inputs() {
    if [ -z "$GITLAB_TOKEN" ]; then
        print_error "GITLAB_TOKEN environment variable is not set"
        echo "Generate a token at: $GITLAB_URL/-/profile/personal_access_tokens"
        echo "Required scopes: api, read_api, write_repository"
        exit 1
    fi

    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID is required"
        usage
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
    
    if echo "$PROJECT_INFO" | grep -q "message.*404"; then
        print_error "Project not found with ID: $PROJECT_ID"
        exit 1
    fi
    
    if echo "$PROJECT_INFO" | grep -q "error"; then
        print_error "Failed to fetch project info: $(echo $PROJECT_INFO | grep -o '"message":"[^"]*"')"
        exit 1
    fi
    
    # Extract current project details
    CURRENT_NAME=$(echo "$PROJECT_INFO" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    CURRENT_VISIBILITY=$(echo "$PROJECT_INFO" | grep -o '"visibility":"[^"]*"' | cut -d'"' -f4)
    CURRENT_DESCRIPTION=$(echo "$PROJECT_INFO" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
    NAMESPACE_ID=$(echo "$PROJECT_INFO" | grep -o '"namespace":{"id":[0-9]*' | grep -o '[0-9]*$')
    
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
    
    DELETE_RESPONSE=$(curl -s -X DELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID")
    
    if echo "$DELETE_RESPONSE" | grep -q "error"; then
        print_error "Failed to delete project: $DELETE_RESPONSE"
        exit 1
    fi
    
    print_success "Project deleted successfully"
    
    # Wait for deletion to complete
    print_status "Waiting for deletion to complete (max 30 seconds)..."
    for i in {1..30}; do
        sleep 1
        curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            "$GITLAB_URL/api/v4/projects/$PROJECT_ID" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
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
    
    if echo "$CREATE_RESPONSE" | grep -q "error"; then
        print_error "Failed to create project: $CREATE_RESPONSE"
        exit 1
    fi
    
    NEW_PROJECT_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -z "$NEW_PROJECT_ID" ]; then
        print_error "Could not extract new project ID from response"
        exit 1
    fi
    
    print_success "Project created successfully!"
    echo ""
    echo "New Project Details:"
    echo "  Name: $new_name"
    echo "  ID: $NEW_PROJECT_ID"
    echo "  Visibility: $new_visibility"
    echo "  URL: $GITLAB_URL/groups/$(echo $CREATE_RESPONSE | grep -o '"path_with_namespace":"[^"]*"' | cut -d'"' -f4)"
}

# Interactive mode
interactive_mode() {
    echo -e "${BLUE}=== GitLab Project Reset Tool ===${NC}"
    echo ""
    
    read -p "GitLab URL [https://gitlab.com]: " gitlab_url
    GITLAB_URL="${gitlab_url:-https://gitlab.com}"
    
    read -sp "GitLab Personal Access Token: " gitlab_token
    GITLAB_TOKEN="$gitlab_token"
    echo ""
    
    read -p "Project ID: " project_id
    PROJECT_ID="$project_id"
    
    read -p "New project name (leave blank to keep current): " project_name
    PROJECT_NAME="$project_name"
    
    read -p "Visibility [private/internal/public] (default: private): " visibility
    PROJECT_VISIBILITY="${visibility:-private}"
}

# Main execution
main() {
    # Show help if requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
    fi
    
    # Interactive mode if no arguments
    if [ -z "$PROJECT_ID" ] && [ -z "$GITLAB_TOKEN" ]; then
        interactive_mode
    fi
    
    validate_inputs
    get_project_info
    confirm_deletion
    delete_project
    recreate_project
    
    echo ""
    print_success "Project reset completed!"
}

main "$@"
