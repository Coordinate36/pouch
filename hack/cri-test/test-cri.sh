#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
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

set -o nounset
set -o pipefail

source $(dirname "${BASH_SOURCE[0]}")/test-utils.sh

POUCH_SOCK="/var/run/pouchcri.sock"

# CRI_FOCUS focuses the test to run.
# With the CRI manager completes its function, we may need to expand this field.
CRI_FOCUS=${CRI_FOCUS:-"PodSandbox|AppArmor|Privileged is true|basic operations on container|Runtime info|mount propagation|volume and device"}

# CRI_SKIP skips the test to skip.
CRI_SKIP=${CRI_SKIP:-""}
# REPORT_DIR is the the directory to store test logs.
REPORT_DIR=${REPORT_DIR:-"/tmp/test-cri"}

# Check GOPATH
if [[ -z "${GOPATH}" ]]; then
  echo "GOPATH is not set"
  exit 1
fi

# For multiple GOPATHs, keep the first one only
GOPATH=${GOPATH%%:*}

CRITEST=${GOPATH}/bin/critest
CRITOOL_PKG=github.com/kubernetes-incubator/cri-tools

# Install critest
if [ ! -x "$(command -v ${CRITEST})" ]; then
  go get -d ${CRITOOL_PKG}/...
  cd ${GOPATH}/src/${CRITOOL_PKG}
  git fetch --all
  git checkout ${CRITOOL_VERSION}
  make
fi
which ${CRITEST}

mkdir -p ${REPORT_DIR}
test_setup ${REPORT_DIR}

# Run cri validation test
sudo env PATH=${PATH} GOPATH=${GOPATH} ${CRITEST} --runtime-endpoint=${POUCH_SOCK} --focus="${CRI_FOCUS}" --ginkgo-flags="--skip=\"${CRI_SKIP}\"" validation
test_exit_code=$?

test_teardown

exit ${test_exit_code}

