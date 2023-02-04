#!/bin/bash

set -e

BRANCH_NAME="develop"

setBranchName() {
	echo ""
	echo "1/8. Getting branch name..."
	BRANCH_NAME="$(git symbolic-ref --short -q HEAD)"
	echo "1/8. Setup for branch: $BRANCH_NAME"
}

setAwsAccountId() {
	echo ""
	echo "4/8. Setting AWS Account Id..."
	if [[ $BRANCH_NAME = "master" ]]
	then
		AWS_ACCOUNT_ID="$PRD_AWS_ACCOUNT_ID"
	elif [[ $BRANCH_NAME = hotfix* ]] || [[ $BRANCH_NAME = release* ]]
	then
		AWS_ACCOUNT_ID="$HML_AWS_ACCOUNT_ID"
	else
		AWS_ACCOUNT_ID="$DEV_AWS_ACCOUNT_ID"
	fi
	echo "4/8. AWS Account Id AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
}

setAwsProfile() {
	echo ""
	echo "5/8. Setting AWS Profile..."
	if [[ $BRANCH_NAME = "master" ]]
	then
		AWS_PROFILE="alpe-prd"
	elif [[ $BRANCH_NAME = hotfix* ]] || [[ $BRANCH_NAME = release* ]]
	then
		AWS_PROFILE="alpe-hml"
	else
		AWS_PROFILE="alpe-dev"
	fi
	echo "5/8. AWS role AWS_PROFILE=$AWS_PROFILE"
}

setAwsRoleArn() {
	echo ""
	echo "6/8. Setting AWS Role ARN..."
	if [[ $BRANCH_NAME = "master" ]]
	then
		AWS_ROLE_ARN="$PRD_AWS_ROLE_ARN"
	elif [[ $BRANCH_NAME = hotfix* ]] || [[ $BRANCH_NAME = release* ]]
	then
		AWS_ROLE_ARN="$HML_AWS_ROLE_ARN"
	else
		AWS_ROLE_ARN="$DEV_AWS_ROLE_ARN"
	fi
	echo "6/8. AWS role AWS_ROLE_ARN=$AWS_ROLE_ARN"
}

login() {
	echo ""
	echo "7/8. Login..."
	AWS_ACCESS_KEY_ID="$DEFAULT_AWS_ACCESS_KEY_ID"
	AWS_SECRET_ACCESS_KEY="$DEFAULT_AWS_SECRET_ACCESS_KEY"
	echo params=$BRANCH_NAME $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_ACCOUNT_ID $AWS_REGION $AWS_PROFILE $AWS_ROLE_ARN
	bash <(curl -s https://bitbucket.org/timefinanceiro/maven-resources/raw/master/src/main/resources/login.sh) $BRANCH_NAME $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_ACCOUNT_ID $AWS_REGION $AWS_PROFILE $AWS_ROLE_ARN
	echo "7/8. End login"
}

setTmpDir() {
	echo ""
	echo "Setting temporary directory..."
	TMP_DIR="$(pwd)/$(date +%s)"
	mkdir ${TMP_DIR}
	echo "Temporary Directory: $TMP_DIR"
}

setVersion() {
	echo ""
	echo "Setting version..."
	VERSION="$(cat pom.xml | xpath -q -e '//project/version/text()')"
	echo "Pom version: $VERSION"
	echo "Branch: $BRANCH_NAME"
	if [[ $BRANCH_NAME = "master" ]]
	then
		VERSION=$( echo "$VERSION" |cut -d "-" -f1 )
		#VERSION=$( echo $VERSION | sed 's/.$//' | sed 's/.$//')
	fi
	echo "Version: $VERSION"
	export SERVICE_VERSION=${ARTIFACT_ID}
}

setArtifactID() {
	echo ""
	echo "Setting artifact id..."
	ARTIFACT_ID="$(cat pom.xml | xpath -q -e '//project/artifactId/text()')"
	echo "Artifact id: $ARTIFACT_ID"
	export SERVICE_NAME=${ARTIFACT_ID}
}

setDownloadURL() {
	echo ""
	echo "Setting downdload url..."
	DOWNLOAD_URL=https://artifactory.alpenet.com.br/artifactory/maven/br/com/alpenet/${ARTIFACT_ID}-stack/${VERSION}/${ARTIFACT_ID}-stack-${VERSION}.tar.gz
	if curl --head --silent --fail -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} $DOWNLOAD_URL 2> /dev/null;
	then
		echo $DOWNLOAD_URL
	else
		DOWNLOAD_URL=https://artifactory.alpenet.com.br/artifactory/maven/tech/alpe/${ARTIFACT_ID}-stack/${VERSION}/${ARTIFACT_ID}-stack-${VERSION}.tar.gz
		echo $DOWNLOAD_URL
	fi
	echo "Download url: $DOWNLOAD_URL"
}

downloadTerraformBundle() {
	echo ""
	echo "Downloading files..."
	curl -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} -fsSL -o ${TMP_DIR}/terraform.tgz $DOWNLOAD_URL
	tar -xzf ${TMP_DIR}/terraform.tgz -C ${TMP_DIR}
	ls -la ${TMP_DIR}
	echo "Download Completed"
}

setKeycloakSecret() {
	echo " "
	echo "Setting Keycloak Secret ..."
	if [[ $BRANCH_NAME = "master" ]]
	then
    	export KEYCLOAK_CLIENT_SECRET=$PRD_KEYCLOAK_CLIENT_SECRET
	else
    	export KEYCLOAK_CLIENT_SECRET=$DEV_HML_KEYCLOAK_CLIENT_SECRET
	fi
	echo "Keycloak Secret Set: $KEYCLOAK_CLIENT_SECRET !"
}

displayEnv() {
	echo ""
	echo "Environment Variables..."
	env
}

applyTerraformBundle() {
	echo ""
	echo "Applying Terraform..."
#	echo ""
#	terragrunt init --terragrunt-working-dir ${TMP_DIR}
	echo ""
	terragrunt plan --terragrunt-working-dir ${TMP_DIR}
	echo ""
	terragrunt apply --terragrunt-working-dir ${TMP_DIR} --auto-approve --terragrunt-debug
	echo ""
	echo "Terraform input"
	echo ""
	cat ${TMP_DIR}/terragrunt-debug.tfvars.json
	echo ""
	echo "Terraform Applied"
}

execute() {
	setBranchName
	setAwsAccountId
	setAwsProfile
	setAwsRoleArn
	login
	setTmpDir
	setVersion
	setArtifactID
	setDownloadURL
	downloadTerraformBundle
	setKeycloakSecret
	displayEnv
	applyTerraformBundle
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

echo "                                          "
echo "                                          "
