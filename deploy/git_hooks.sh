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
all_changes_files_in_commit=$(git show --name-only --oneline $last_commit)
local_branch="$(git rev-parse --abbrev-ref HEAD)"
# echo $local_branch
if [[ $local_branch == *"master"* || $local_branch == *"developers"* ]]; then
# if [[ $local_branch == *"developers"* ]]; then
    printf "\t\033[0;36mRunning pre-commit checks on your code...\033[0m\n"
    all_path=$(echo $all_changes_files_in_commit | tr -s " " "\012")
    PASS=true

    for addr in $all_path
        do
            # [ -d "$addr" ] && echo "directory"
            # [ -f "$addr" ] && echo "file"
            dir_name=$(dirname "${addr}")
        if [[ $dir_name != *"."* ]]; then
            # echo $dir_name
            FILES=$(go list ./$dir_name/...)
            # Start GOLANG Static analysis...
            # ===============================================
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
                    printf "\033[32mgolint $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n"
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
	            # errcheck -ignoretests ${FILES} ????
                errcheck ${FILES}
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
            # ===============================================
        fi
    done
else
    printf "\t\033[41mIncorrect GIT branch\033[0m\n"
    exit 1
fi