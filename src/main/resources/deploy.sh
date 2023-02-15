#!/bin/bash

set -e

BRANCH_NAME="develop"

setBranchName() {
	echo ""
	echo "1/4. Setting git branch name..."
	BRANCH_NAME="$(git symbolic-ref --short -q HEAD)"
	echo "1/4. Git branch name: $BRANCH_NAME successfully setted"
}

setGroupId() {
	echo ""
	echo "2/4. Setting group id..."
	GROUP_ID="$(cat pom.xml | xpath -q -e '//project/groupId/text()')"
	echo "2/4. Group id: $GROUP_ID successfully setted"
}

setArtifactId() {
	echo ""
	echo "3/4. Setting artifact id..."
	ARTIFACT_ID="$(cat pom.xml | xpath -q -e '//project/artifactId/text()')"
	echo "3/4. Artifact id: $ARTIFACT_ID successfully setted"
}

setVersion() {
	echo ""
	echo "4/4. Setting version..."
	VERSION="$(cat pom.xml | xpath -q -e '//project/version/text()')"
	if [[ $BRANCH_NAME = "master" ]]
	then
		VERSION=$( echo "$VERSION" |cut -d "-" -f1 )
	fi
	echo "4/4. Version: $VERSION successfully setted"
}

applyTerraform() {
	/opt/pipelines/terragrunt.sh apply $BRANCH_NAME $GROUP_ID $ARTIFACT_ID $VERSION tar.gz
}

execute() {
	setBranchName
	setGroupId
	setArtifactId
	setVersion
	applyTerraform
}

echo "                                          "
echo "                     ________             "
echo "         ____   ____/   __   \            "
echo "        / ___\ /  _ \____    /            "
echo "       / /_/  >  <_> ) /    /             "
echo "       \___  / \____/ /____/              "
echo "      /_____/                             "
echo "                    Starting deploy...    "
echo "                                          "
echo "                                          "
echo " Deploy script version: @project.version@ "
echo "                                          "
echo "                                          "
execute
