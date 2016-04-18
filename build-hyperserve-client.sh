#!/bin/bash

VERSION=$(< ./VERSION)
if command -v git &> /dev/null && git rev-parse &> /dev/null; then
	GITCOMMIT=$(git rev-parse --short HEAD)
	if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
		GITCOMMIT="$GITCOMMIT-beta"
	fi
	BUILDTIME=$(date -u)
elif [ "$HYPER_GITCOMMIT" ]; then
	GITCOMMIT="$HYPER_GITCOMMIT"
else
	echo >&2 'error: .git directory missing and HYPER_GITCOMMIT not specified'
	echo >&2 '  Please either build with the .git directory accessible, or specify the'
	echo >&2 '  exact (--short) commit hash you are building using HYPER_GITCOMMIT for'
	echo >&2 '  future accountability in diagnosing build issues.  Thanks!'
	exit 1
fi

cat > dockerversion/version_autogen.go <<DVEOF
// +build autogen

// Package dockerversion is auto-generated at build-time
package dockerversion

// Default build-time variable for library-import.
// This file is overridden on build with build-time informations.
const (
	GitCommit string = "$GITCOMMIT"
	Version   string = "$VERSION"
	BuildTime string = "$BUILDTIME"
	IAmStatic string = "${IAMSTATIC:-true}"
)
// AUTOGENERATED FILE; see $BASH_SOURCE
DVEOF

CLI_ROOT=$(dirname "{BASH_SOURCE}")
export DOCKER_CLIENTONLY=yes
cd ${CLI_ROOT}
export GOPATH=$(pwd)/vendor:$GOPATH
cd $(pwd)/hyper
go build -ldflags "-s -w" -tags autogen .