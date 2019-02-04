#!/usr/bin/env bash
# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1

    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $(( attempt_num++ ))
        fi
    done
}

TAG_NUM=$1
ORG=$2
RELEASE=$3
TAG=$TAG_NUM

export DOCKER_REGISTRY=docker.io
export TAG

echo "Building ${DOCKER_REGISTRY}/${ORG}/jenkins-filerunner:${TAG}"
head -n 1 Dockerfile
retry 3 skaffold build -f skaffold.yaml
echo "Built ${DOCKER_REGISTRY}/${ORG}/jenkins-filerunner:${TAG}"

if [ "release" == "${RELEASE}" ]; then
    jx step tag --version $TAG_NUM
fi

if [ "release" == "${RELEASE}" ]; then
    updatebot push-version --kind docker ${ORG}/jenkins-filerunner ${TAG}
fi
