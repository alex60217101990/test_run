#!/bin/bash
last_commit=$(git rev-parse HEAD 2>&1)
all_changes_files_in_commit=$(git show --name-only --oneline $last_commit)
local_branch="$(git rev-parse --abbrev-ref HEAD)"
# echo $local_branch
if [[ $local_branch == *"master"* || $local_branch == *"developers"* ]]; then
# if [[ $local_branch == *"developers"* ]]; then
    printf "\t\033[0;36mRunning pre-commit checks on your code...\033[0m\n"
    all_path=$(echo $all_changes_files_in_commit | tr -s " " "\012")
    for addr in $all_path
        do
            # [ -d "$addr" ] && echo "directory"
            # [ -f "$addr" ] && echo "file"
            dir_name=$(dirname "${addr}")
        if [[ $dir_name != *"."* ]]; then
            echo $dir_name
            FILES=$(go list ./$dir_name/...  | grep -v /vendor/)
            echo $FILES
        fi
    done
else
    printf "\t\033[41mIncorrect git branch\033[0m\n"
    exit 1
fi 


#| grep -o '(\/?.*?\/)((?:[^\/]|\\\/)+?)(?:(?<!\\)\s|$)'
# sed 's:[^/]*::;s/ .*//'
# grep -oP '\/.*\.[\w:]+'
# '\/.*\.[\w:]+'