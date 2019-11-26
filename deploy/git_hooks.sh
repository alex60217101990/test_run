#!/bin/bash
last_commit=$(git rev-parse HEAD 2>&1)
git show --name-only $last_commit
#echo $last_commit