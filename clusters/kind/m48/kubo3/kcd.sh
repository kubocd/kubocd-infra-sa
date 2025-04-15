#!/bin/bash

export MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBOCD=$( cd "$MYDIR/../../../../../kubocd/" && pwd)

cd "${KUBOCD}" &&  if ! make build-kubocd; then exit $?; fi >/dev/stderr

cd "${MYDIR}" || exit

export OCI_REPO_PREFIX=quay.io/kubocd/packages
#export OCI_REPO_PREFIX=localhost:5001/packages
#export OCI_REPO_PREFIX=ghcr.io/sergealexandre/kubocd/packages

set +x
"${KUBOCD}/bin/kubocd" "$@"

