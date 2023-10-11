#!/bin/bash

# Create an .env file containing 
# your GitLab API token and the organization name
# and API base URL
#
# GITLAB_TOKEN="YOUR_GITLAB_API_TOKEN"
# GITLAB_ORG="YOUR_ORGANIZATION_NAME"
# GITLAB_API_BASE_URL="https://gitlab.com/api/v4"
#!/bin/bash

# Display help message if requested or if no organization is provided
if [ "$1" == "-h" ] || [ -z "$1" ]; then
  echo "Usage: $0 ORGANIZATION_NAME [TARGET_DIR]"
  echo "Clone GitLab repositories from the specified organization into the target directory."
  exit 1
fi

# Set the GitLab organization and target directory (defaults to the current directory)
GITLAB_ORG="$1"
TARGET_DIR="${2:-.}"

# Ensure the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory '$TARGET_DIR' does not exist. Creating it..."
  mkdir -p "$TARGET_DIR"
fi

# Function to retrieve all the groups in the organization
get_groups() {
  local org_name="$1"
  curl --header "Private-Token: $GITLAB_TOKEN" "$GITLAB_API_BASE_URL/groups?search=$org_name"
}

# Function to list all projects in a group
list_projects_in_group() {
  local group_id="$1"
  curl --header "Private-Token: $GITLAB_TOKEN" "$GITLAB_API_BASE_URL/groups/$group_id/projects"
}

# Function to clone a Git repository
clone_repository() {
  local repo_url="$1"
  git clone "$repo_url"
}

# Function to iterate through all subgroups recursively
recurse_groups() {
  local parent_group="$1"
  local parent_path="$2"

  # Get a list of subgroups and projects in the current group
  local group_info=$(get_groups "$parent_group")
  local group_id=$(echo "$group_info" | jq -r '.[0].id')

  if [ "$group_id" != "null" ]; then
    local subgroups=$(echo "$group_info" | jq -r '.[0].subgroups | .[] | .full_path')
    local projects=$(list_projects_in_group "$group_id" | jq -r '.[].ssh_url_to_repo')

    # Create a directory for the current group and cd into it
    mkdir -p "$parent_path/$parent_group"
    cd "$parent_path/$parent_group"

    # Clone projects in the current group
    for project in $projects; do
      echo "Cloning repository: $project"
      clone_repository "$project"
    done

    # Recursively call this function for subgroups
    for subgroup in $subgroups; do
      recurse_groups "$subgroup" "$parent_path/$parent_group"
    done

    # Return to the parent directory
    cd ..
  fi
}

# Main script
echo "Cloning GitLab repositories for organization: $GITLAB_ORG into target directory: $TARGET_DIR"
recurse_groups "$GITLAB_ORG" "$TARGET_DIR"
