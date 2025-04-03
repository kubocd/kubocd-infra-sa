#!/bin/bash

export MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${MYDIR}/.kubeconfig

export KUBOCD=$( cd "$MYDIR/../../../../../kubocd/" && pwd)


cd "${KUBOCD}" &&  if ! make build-kubocd; then exit $?; fi >/dev/stderr

cd "${MYDIR}" || exit

export MY_POD_NAMESPACE=kubocd
"${KUBOCD}/bin/kubocd" controller --logLevel DEBUG --rootDataFolder ./tmp --sourceControllerOverride flux-sources.ingress.kad1.mbp --helmRepoAdvAddr "host.docker.internal:9090" "$@"

