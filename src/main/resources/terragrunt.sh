#!/bin/bash

set -e

COMMAND=$1
BRANCH_NAME=$2
GROUP_ID=$3
ARTIFACT_ID=$4
VERSION=$5
PACKAGING=$6
CLASSIFIER=$7

validateInput() {
	echo ""
}

setBranchName() {
	echo ""
	echo "Setting branch name..."
	if [[ -z "$BRANCH_NAME" ]]
	then
		BRANCH_NAME="$(git symbolic-ref --short -q HEAD)"
	fi
	echo "Branch name: $BRANCH_NAME successfully setted"
	echo ""
}

setTmpDir() {
	echo ""
	echo "Setting temporary directory..."
	TMP_DIR="$(pwd)/$(date +%s)"
	mkdir ${TMP_DIR}
	echo "Temporary directory: $TMP_DIR successfully setted"
	echo ""
}

setArtifact() {
	echo ""
	echo "Setting artifact..."
	ARTIFACT="${GROUP_ID}:${ARTIFACT_ID}:${VERSION}:${PACKAGING}"
	if [[ ! -z "$CLASSIFIER" ]]
	then
		ARTIFACT="${ARTIFACT}:${CLASSIFIER}"
	fi
	echo "Artifact: $ARTIFACT successfully setted"
	echo ""
}

downloadTerraformBundle() {
	echo ""
	echo "Downloading terraform bundle..."
	cd $TMP_DIR
	mvn dependency:copy -Dartifact=${ARTIFACT} -DoutputDirectory=. -DstripVersion=true
	echo "Terraform bundle: $ARTIFACT successfully downloaded"
	ls -la .
	cd ..
	echo ""
}

extractTerraformBundle() {
	echo ""
	echo "Extracting terraform bundle..."
	cd $TMP_DIR
	tar -xzf $(eval find . -maxdepth 1 -mindepth 1 -name '*.tar.gz') -C .
	echo "Terraform bundle: $ARTIFACT successfully extracted"
	ls -la .
	cd ..
	echo ""
}

applyTerraformBundle() {
	echo ""
	echo "Applying Terraform..."
	echo ""
	terragrunt init --terragrunt-working-dir ${TMP_DIR}
	echo ""
	terragrunt plan --terragrunt-working-dir ${TMP_DIR}
	echo ""
	terragrunt ${COMMAND} --terragrunt-working-dir ${TMP_DIR} --auto-approve --terragrunt-debug
	echo ""
	echo "Terraform input"
	echo ""
	cat ${TMP_DIR}/terragrunt-debug.tfvars.json
	echo ""
	echo "Terraform successfully applied"
	echo ""
}

execute() {
	validateInput
	setBranchName
	setTmpDir
	setArtifact
	downloadTerraformBundle
	extractTerraformBundle
	applyTerraformBundle
}

execute
