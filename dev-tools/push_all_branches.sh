#!/bin/bash

# Get the remote repository URL
remote_url=$(git config --get remote.origin.url)

# Check if the remote URL is set
if [ -z "$remote_url" ]; then
    echo "Error: No remote repository URL found."
    exit 1
fi

# Get the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Add all changes to the staging area for the current branch
git add .

# Commit the staged changes for the current branch
commit_message="Pushing to remote for storage"
git commit -m "$commit_message"

# Push the current branch to the remote repository
git push --set-upstream "$remote_url" "$current_branch"

# Get a list of all local branches
branches=$(git branch | grep -v "^\*" | xargs)

# Loop through each branch and push to the remote repository
for branch in $branches
do
    # Check if the remote tracking branch exists
    remote_branch=$(git rev-parse --abbrev-ref "$branch@{upstream}" 2>/dev/null)

    if [ -z "$remote_branch" ]; then
        # Remote tracking branch doesn't exist, set it up
        git push --set-upstream "$remote_url" "$branch"
    else
        # Remote tracking branch exists, push the branch
        git push "$remote_url" "$branch"
    fi
done

# Checkout the original branch
git checkout "$current_branch"

echo "All local branches have been pushed to the remote repository."
