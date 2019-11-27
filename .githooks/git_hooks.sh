#!/bin/bash

GOLINT=$GOPATH/bin/golint
GOIMPORTS=$GOPATH/bin/goimports

# Check for golint
if [[ ! -x "$GOLINT" ]]; then
  printf "\t\033[41mPlease install golint\033[0m (go get -u golang.org/x/lint/golint)"
  exit 1
fi

# Check for goimports
if [[ ! -x "$GOIMPORTS" ]]; then
  printf "\t\033[41mPlease install goimports\033[0m (go get golang.org/x/tools/cmd/goimports)"
  exit 1
fi

last_commit=$(git rev-parse HEAD 2>&1)
all_changes_files_in_commit=$(git show --name-only --oneline -- '*.go' $last_commit)
local_branch="$(git rev-parse --abbrev-ref HEAD)"

username="$(git config --list --local | grep user.email | cut -d'=' -f2 | cut -d'@' -f1)"
valid_user_branch_regex="(feature|bugfix|hotfix)-[a-z]{1,15}\/[A-Z]{1,5}-[0-9]{1,6}"
valid_release_branch_regex="release-\d{1,3}.\d{1,3}.\d{1,3}"
admins=(skreitor rterentev sambaryan vstoyanov)
is_not_admin=true

if [[ "${admins[*]}" == *"${username}"* ]];
then
    printf "\033[32mUser ${username} is an admin\033[0m \033[0;30m\n"
    is_not_admin=false
else
    printf "\033[32mUser ${username} is NOT an admin\033[0m \033[0;30m\n"
fi

wrong_user_branch=true
if [[ $local_branch =~ $valid_user_branch_regex ]]; then
 $wrong_user_branch=false
fi
wrong_release_branch=false
if [[ $local_branch =~ $valid_release_branch_regex ]]; then
 $wrong_release_branch=true
fi
if $is_not_admin && ($wrong_user_branch || $wrong_release_branch); then
    printf "\n\t\033[41mThere is something wrong with your branch name. Branch names in this project must adhere to this contract:\033[0m\n"
    printf "\n\t\033[41m'feature(bugfix/hotfix)-skreitor/PLA-1002' or 'release-1.2.3'.\033[0m\n"
    printf "\n\t\033[41mYour push will be rejected. You should rename your branch to a valid name and try again.\033[0m\n"
    exit 1
else
if [[ $local_branch == *"master"* || $local_branch == *"developers"* ]]; then
    printf "\033[0;36mRunning pre-commit checks on your code...\033[0m\n"
    all_path=$(echo $all_changes_files_in_commit | tr -s " " "\012")
    PASS=true
    for addr in $all_path
        do
            dir_name=$(dirname "${addr}")
        if [[ $dir_name != *"."* ]]; then
            FILES=$(go list ./$dir_name/...)
            # Start GOLANG Static analysis...
            # Format the Go code
            printf "\033[31m"
            go fmt ${FILES}
            printf "\033[0m"
            for FILE in $FILES 
            do 
                git add $FILE
                # Run goimports on the staged file
                $GOIMPORTS -w $FILE
                # Run golint on the staged file and check the exit status
                $GOLINT "-set_exit_status" $FILE
                if [[ $? == 1 ]]; then
                    printf "\033[31mgolint $FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n"
                    PASS=false
                else
                    printf "\033[32mgolint $FILE\033[0m \033[0;30m\n"
                fi
            done
            if ! $PASS; then
                printf "\033[0;30m\033[41mGOLINT FAILED\033[0m\n"
                exit 1
            else
                printf "\033[0;30m\033[42mGOLINT SUCCEEDED\033[0m\n"
            fi
            # Check all files for errors
            {
	            errcheck -ignoretests ${FILES}
            } || {
	            exitStatus=$?
	            if [ $exitStatus ]; then
		            printf "\n\t\033[41mErrors found in your code, please fix them and try again.\033[0m\n"
		            exit 1
	            fi
            }
            # Check all files for suspicious constructs
            {
	            go vet ${FILES}
            } || {
	            exitStatus=$?
	            if [ $exitStatus ]; then
		            printf "\n\t\033[41mIssues found in your code, please fix them and try again.\033[0m\n"
		            exit 1
	            fi
            }
        else
            is_present=$(find . -iname ${addr})
            printf "\033[0;35mFile present on root project directory: $is_present\033[0m\n"
            if [ ! -z "$is_present" ]
            then
                # Start GOLANG Static analysis...
                # Format the Go code
                printf "\033[31m"
                go fmt ${is_present}
                printf "\033[0m"

                git add $is_present
                # Run goimports on the staged file
                $GOIMPORTS -w $is_present
                # Run golint on the staged file and check the exit status
                $GOLINT "-set_exit_status" $is_present
                if [[ $? == 1 ]]; then
                    printf "\033[31mgolint $is_present\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n"
                    PASS=false
                else
                    printf "\033[32mgolint $is_present\033[0m \033[0;30m\n"
                fi
                if ! $PASS; then
                    printf "\033[0;30m\033[41mGOLINT FAILED\033[0m\n"
                    exit 1
                else
                    printf "\033[0;30m\033[42mGOLINT SUCCEEDED\033[0m\n"
                fi
                # Check all files for errors
                {
	                errcheck -ignoretests ${is_present}
                } || {
	                exitStatus=$?
	                if [ $exitStatus ]; then
		                printf "\n\t\033[41mErrors found in your code, please fix them and try again.\033[0m\n"
		                exit 1
	                fi
                }
                # Check all files for suspicious constructs
                {
	                go vet ${is_present}
                } || {
	                exitStatus=$?
	                if [ $exitStatus ]; then
		                printf "\n\t\033[41mIssues found in your code, please fix them and try again.\033[0m\n"
		                exit 1
	                fi
                }
                
            fi    
        fi
    done
# else
#     printf "\t\033[41mIncorrect GIT branch\033[0m\n"
#     exit 1
fi