FROM openjdk:19-jdk-slim

USER root


# coreutils

RUN apt-get update \
  && apt-get -y install coreutils \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*


# curl

RUN apt-get update \
  && apt-get -y install curl \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*


# gettext

RUN apt-get update \
  && apt-get -y install gettext-base \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*


# gpg

RUN apt-get update \
  && apt-get -y install gnupg2 \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/* \
  && gpg --version


# unzip

RUN apt-get update \
  && apt-get -y install unzip \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*


# Git

RUN apt-get update \
  && apt-get -y install git-core \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/*


# Maven
ARG MAVEN_VERSION=3.8.7
#ARG MAVEN_SHA=0ec48eb515d93f8515d4abe465570dfded6fa13a3ceb9aab8031428442d9912ec20f066b2afbf56964ffe1ceb56f80321b50db73cf77a0e2445ad0211fb8e38d
ARG MAVEN_BASE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/maven.tar.gz ${MAVEN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
#  && echo "${MAVEN_SHA} /tmp/maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
  && mvn --version

ENV MAVEN_HOME /usr/share/maven

COPY target/settings-ci.xml /root/.m2/settings.xml


# Terrafrom

ARG TERRAFORM_VERSION=1.3.7
ARG TERRAFORM_BASE_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}

RUN curl -fsSL -o /tmp/terraform.zip ${TERRAFORM_BASE_URL}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && unzip /tmp/terraform.zip -d /usr/bin \
  && rm -f /tmp/terraform.zip \
  && terraform --version


# Terragrunt

ARG TERRAGRUNT_VERSION=v0.43.2
ARG TERRAGRUNT_BASE_URL=https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}

RUN curl -sS -L ${TERRAGRUNT_BASE_URL}/terragrunt_linux_amd64 -o /usr/bin/terragrunt \
  && chmod +x /usr/bin/terragrunt \
  && terragrunt --version


# Maven Central Signature

ARG GPG_PASSPHRASE

COPY target/maven-central-signature.tpl ./maven-central-signature.tpl
RUN export GPG_PASSPHRASE=$GPG_PASSPHRASE \
  && envsubst < maven-central-signature.tpl > maven-central-signature.gpg \
  && gpg --batch --generate-key maven-central-signature.gpg \
  && rm maven-central-signature.* \
  && gpg --list-secret-keys


# Custom scripts

COPY target/build.sh /opt/pipelines/build.sh
COPY target/terragrunt.sh /opt/pipelines/terragrunt.sh
COPY target/deploy.sh /opt/pipelines/deploy.sh

RUN chmod +x /opt/pipelines/build.sh \
  && chmod +x /opt/pipelines/deploy.sh \
  && echo "export PATH=$PATH:/opt/pipelines" >> ~/.bashrc
