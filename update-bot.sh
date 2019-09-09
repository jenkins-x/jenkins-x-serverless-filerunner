#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

jx step create pr docker \
    --name gcr.io/jenkinsxio/jenkins-filerunner \
    --version ${VERSION} \
    --repo https://github.com/jenkins-x/jenkins-x-serverless.git
