#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Get the main branch name (can be main or master)
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
if [ -z "$MAIN_BRANCH" ]; then
  MAIN_BRANCH="main"
fi

# Get all local branches
BRANCHES=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(committerdate:relative);%(refname:short);%(objectname:short);%(contents:subject);%(authorname)')

# For each branch, check if it's merged
while IFS= read -r branch_info; do
  is_head=$(echo "$branch_info" | cut -d ';' -f 1 | grep -q '*' && echo "* " || echo " ")
  rel_date=$(echo "$branch_info" | cut -d ';' -f 1 | sed 's/*//')
  branch=$(echo "$branch_info" | cut -d ';' -f 2)
  sha=$(echo "$branch_info" | cut -d ';' -f 3)
  subject=$(echo "$branch_info" | cut -d ';' -f 4)
  author=$(echo "$branch_info" | cut -d ';' -f 5)

  # Skip main branch from checking merged status
  if [ "$branch" = "$MAIN_BRANCH" ]; then
    echo -e "${is_head}${DIM}${GREEN}${rel_date}${RESET} ${YELLOW}${branch}${RESET} - ${RED}${sha}${RESET} ${DIM}- ${subject} ${author}${RESET}"
    continue
  fi

  # Check if branch is merged to main using GitHub API
  merged_status=""
  pr_info=$(gh pr list --head "$branch" --state all --json number,state --jq '.[0]' 2>/dev/null)
  pr_number=$(echo "$pr_info" | jq -r '.number // ""')
  pr_state=$(echo "$pr_info" | jq -r '.state // ""')

  pr_display=""
  if [ ! -z "$pr_number" ]; then
    if [ "$pr_state" = "MERGED" ]; then
      merged_status="${GREEN}merged #$pr_number${RESET}"
    elif [ "$pr_state" = "CLOSED" ]; then
      merged_status="${RED}closed #$pr_number${RESET}"
    elif [ "$pr_state" = "OPEN" ]; then
      merged_status="${DIM}open #$pr_number${RESET}"
    fi
    pr_display="${merged_status}"
  fi

  # Check if branch is already merged to main using git (faster fallback)
  if [ -z "$merged_status" ]; then
    if git merge-base --is-ancestor "$branch" "$MAIN_BRANCH" 2>/dev/null; then
      if [ -z "$pr_state" ]; then  # Only show this if we didn't find a PR
        merged_status="${GREEN}merged-git${RESET}"
        pr_display="${merged_status}"
      fi
    fi
  fi

  echo -e "${is_head}${DIM}${GREEN}${rel_date}${RESET} ${YELLOW}${branch}${RESET} ${DIM}- ${subject} ${author}${RESET} ${RED}${sha}${RESET} ${pr_display}"
done <<< "$BRANCHES"
