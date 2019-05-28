FROM jenkins/jenkins:2.164.3 as jenkins
USER root

ENV CWP_VERSION 1.0-SNAPSHOT
ADD tmp/output/target/jenkins-x-serverless-${CWP_VERSION}.war /usr/share/jenkins/jenkins.war
RUN mkdir /app && unzip /usr/share/jenkins/jenkins.war -d /app/jenkins
COPY tmp/output/jenkinsfileRunner /app
RUN chmod +x /app/bin/jenkinsfile-runner && mkdir -p /usr/share/jenkins/ref/plugins && \
  rm -rf /app/jenkins/scripts /app/jenkins/jsbundles /app/jenkins/css \
  /app/jenkins/images /app/jenkins/help /app/jenkins/WEB-INF/detached-plugins \
  /app/jenkins/winstone.jar /app/jenkins/WEB-INF/jenkins-cli.jar \
  /app/jenkins/WEB-INF/lib/jna-4.5.2.jar
COPY tmp/output/plugins /usr/share/jenkins/ref/plugins

FROM openjdk:8-jdk
RUN mkdir -p /app /usr/share/jenkins/ref/plugins

 # we don't need all the repo
COPY --from=jenkins /app/jenkins /app/jenkins
COPY --from=jenkins /app/bin /app/bin
COPY --from=jenkins /app/repo /app/repo
COPY --from=jenkins /usr/share/jenkins/ref/plugins /usr/share/jenkins/ref/plugins

ENTRYPOINT ["/app/bin/jenkinsfile-runner", \
            "-w", "/app/jenkins",\
            "-p", "/usr/share/jenkins/ref/plugins",\
            "-f", "/workspace/Jenkinsfile"]

RUN apt-get update && apt-get install -y \
  wget \
  bzip2 \
  python-pip \
  postgresql-client \
  build-essential \
  make \
  bzip2 \
  zip \
  unzip \
  autoconf

RUN pip install --upgrade pip anchorecli

# USER jenkins
WORKDIR /home/jenkins

# Docker
ENV DOCKER_VERSION 17.12.0
RUN curl -f https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION-ce.tgz | tar xvz && \
  mv docker/docker /usr/bin/ && \
  rm -rf docker

# helm
ENV HELM_VERSION 2.13.1
RUN curl -f https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz  | tar xzv && \
  mv linux-amd64/helm /usr/bin/ && \
  rm -rf linux-amd64

# helm3
RUN curl -L https://get.helm.sh/helm-v3.0.0-alpha.1-linux-amd64.tar.gz | tar xzv && \
  mv linux-amd64/helm /usr/bin/helm3 && \
  rm -rf linux-amd64

# gcloud
ENV GCLOUD_VERSION 239.0.0
RUN curl -Lf https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz | tar xzv && \
  mv google-cloud-sdk /usr/bin/
ENV PATH=$PATH:/usr/bin/google-cloud-sdk/bin

# install the docker credential plugin
RUN gcloud components install docker-credential-gcr

# jx-release-version
ENV JX_RELEASE_VERSION 1.0.10
RUN curl -o ./jx-release-version -Lf https://github.com/jenkins-x/jx-release-version/releases/download/v${JX_RELEASE_VERSION}/jx-release-version-linux && \
  mv jx-release-version /usr/bin/ && \
  chmod +x /usr/bin/jx-release-version

# exposecontroller
ENV EXPOSECONTROLLER_VERSION 2.3.34
RUN curl -Lf https://github.com/fabric8io/exposecontroller/releases/download/v$EXPOSECONTROLLER_VERSION/exposecontroller-linux-amd64 > exposecontroller && \
  chmod +x exposecontroller && \
  mv exposecontroller /usr/bin/

# skaffold
ENV SKAFFOLD_VERSION 0.30.0
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-amd64 && \
  chmod +x skaffold && \
  mv skaffold /usr/bin

# container structure test
RUN curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && \
  chmod +x container-structure-test-linux-amd64 && \
  mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# updatebot
ENV UPDATEBOT_VERSION 1.1.41
RUN curl -o ./updatebot -Lf https://oss.sonatype.org/content/groups/public/io/jenkins/updatebot/updatebot/${UPDATEBOT_VERSION}/updatebot-${UPDATEBOT_VERSION}.jar && \
  chmod +x updatebot && \
  cp updatebot /usr/bin/ && \
  rm -rf updatebot

# draft
RUN curl -f https://azuredraft.blob.core.windows.net/draft/draft-canary-linux-amd64.tar.gz  | tar xzv && \
  mv linux-amd64/draft /usr/bin/ && \
  rm -rf linux-amd64

# kubectl
RUN curl -LOf https://storage.googleapis.com/kubernetes-release/release/$(curl -sf https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/bin/

# aws ecr docker credential helper.
# Currently using https://github.com/estahn/amazon-ecr-credential-helper as there are no releases yet in the main repo
# Main repo issues tracking at https://github.com/awslabs/amazon-ecr-credential-helper/issues/80
RUN mkdir ecr && \
    curl -Lf https://github.com/estahn/amazon-ecr-credential-helper/releases/download/v0.1.1/amazon-ecr-credential-helper_0.1.1_linux_amd64.tar.gz | tar -xzv -C ./ecr/ && \
    mv ecr/docker-credential-ecr-login /usr/bin/ && \
    rm -rf ecr

# ACR docker credential helper
#??https://github.com/Azure/acr-docker-credential-helper
RUN mkdir acr && \
    curl -Lf https://aadacr.blob.core.windows.net/acr-docker-credential-helper/docker-credential-acr-linux-amd64.tar.gz | tar -xzv -C ./acr/ && \
    mv acr/docker-credential-acr-linux /usr/bin/ && \
    rm -rf acr

# Git
ENV GIT_VERSION 2.21.0
RUN apt-get update && apt install -y make libssl-dev libghc-zlib-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip wget && \
  cd /usr/src  && \
  wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz  && \
  tar xzf git-${GIT_VERSION}.tar.gz  && \
  cd git-${GIT_VERSION} && \
  make prefix=/usr all  && \
  make prefix=/usr install

# goreleaser
ENV GORELEASER_VERSION 0.93.2
# See https://goreleaser.com/
RUN mkdir goreleaser && \
    curl -Lf https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz | tar -xzv -C ./goreleaser/ && \
    mv goreleaser/goreleaser /usr/bin/ && \
    rm -rf goreleaser

ENV JQ_RELEASE_VERSION 1.5
RUN wget https://github.com/stedolan/jq/releases/download/jq-${JQ_RELEASE_VERSION}/jq-linux64 && mv jq-linux64 jq && chmod +x jq && cp jq /usr/bin/jq
