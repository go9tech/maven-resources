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
}

setTmpDir() {
	echo ""
	echo "Setting temporary directory..."
	TMP_DIR="$(pwd)/$(date +%s)"
	mkdir ${TMP_DIR}
	echo "Temporary directory: $TMP_DIR successfully setted"
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
}

downloadTerraformBundle() {
	echo ""
	echo "Downloading terraform bundle..."
	mvn dependency:copy -Dartifact=${ARTIFACT} -DoutputDirectory=${TMP_DIR} -DstripVersion=true
	if [[ ! -z "$CLASSIFIER" ]]
	then
		TF_BUNDLE=${TMP_DIR}/${ARTIFACT_ID}-${CLASSIFIER}.${PACKAGING}
	else
		TF_BUNDLE=${TMP_DIR}/${ARTIFACT_ID}.${PACKAGING}
	fi
	ls -la $TMP_DIR
	echo "Terraform bundle: $TF_BUNDLE successfully downloaded"
}

extractTerraformBundle() {
	echo ""
	echo "Extracting terraform bundle..."
	tar -xzf ${TF_BUNDLE} -C ${TMP_DIR}
	rm ${TF_BUNDLE}
	ls -la $TMP_DIR
	echo "Terraform bundle: $TF_BUNDLE successfully extracted"
	echo ""
	ls -la $TMP_DIR
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
	echo "Terraform Applied"
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
