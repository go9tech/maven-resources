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
		MVN_COMMAND="$MVN_COMMAND release:prepare release:perform --batch-mode -Darguments=-Dgpg.passphrase=$MAVEN_CENTRAL_PASSWORD"
	elif [[ $BRANCH_NAME = hotfix* ]] || [[ $BRANCH_NAME = release* ]] || [[ $BRANCH_NAME = "develop" ]]
	then
		MVN_COMMAND="$MVN_COMMAND deploy -Dgpg.passphrase=$MAVEN_CENTRAL_PASSWORD"
	else
		MVN_COMMAND="$MVN_COMMAND verify -Dgpg.passphrase=$MAVEN_CENTRAL_PASSWORD"
	fi
	echo "3/3. Maven command: $MVN_COMMAND successfully setted"
}

execute() {
	setBranchName
	setGitConfig
	setMavenCommand
	echo "                                         "
	echo "                                         "
	$MVN_COMMAND
}

echo "                                          "
echo "                     ________             "
echo "         ____   ____/   __   \            "
echo "        / ___\ /  _ \____    /            "
echo "       / /_/  >  <_> ) /    /             "
echo "       \___  / \____/ /____/              "
echo "      /_____/                             "
echo "                    Starting build...     "
echo "                                          "
echo "                                          "
echo " Build script version: @project.version@  "
echo "                                          "
echo "                                          "
execute
