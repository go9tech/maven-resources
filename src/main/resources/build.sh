#!/bin/bash

set -e

BRANCH_NAME="develop"
MVN_COMMAND="mvn -U post-clean"

setBranchName() {
	echo ""
	echo "1/3. Setting git branch name..."
	BRANCH_NAME="$(git symbolic-ref --short -q HEAD)"
	echo "1/3. Git branch name: $BRANCH_NAME successfully setted"
}

setGitConfig() {
	echo ""
	echo "2/3. Configuring Git ..."
	git config --global user.name "$GIT_USERNAME"
	git config --global user.email "$GIT_EMAIL"
	git config --global user.password "$GIT_PASSWORD"
	echo "2/3. Git successfully configured for user: $GIT_USERNAME, email: $GIT_EMAIL and password: $GIT_PASSWORD"
}

setMavenCommand() {
	echo ""
	echo "3/3. Setting Maven command ..."
	if [[ $BRANCH_NAME = master ]]
	then
		MVN_COMMAND="$MVN_COMMAND release:prepare release:perform --batch-mode"
	elif [[ $BRANCH_NAME = hotfix* ]] || [[ $BRANCH_NAME = release* ]] || [[ $BRANCH_NAME = "develop" ]]
	then
		MVN_COMMAND="$MVN_COMMAND deploy"
	else
		MVN_COMMAND="$MVN_COMMAND verify"
	fi
	echo "3/3. Maven command: $MVN_COMMAND successfully setted"
}

generateGpg

displayEnv() {
	echo ""
	echo "Environment Variables..."
	env
}

execute() {
	setBranchName
	setGitConfig
	setMavenCommand
	displayEnv
}

echo "                                          "
echo "        ___  _                            "
echo "       / _ \| |                           "
echo "      / /_\ \ |_ __   ___                 "
echo "      |  _  | | '_ \ / _ \                "
echo "      | | | | | |_) |  __/                "
echo "      \_| |_/_| .__/ \___|                "
echo "              | |                         "
echo "              |_|   Starting build...     "
echo "                                          "
echo "                                          "
echo " Build script version: @project.version@  "
echo "                                          "
echo "                                          "

execute

echo "                                         "
echo "                                         "

$MVN_COMMAND
