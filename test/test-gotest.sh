#!/usr/bin/env bash

echo running "$0" "$@"

#ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"	# dir!
ROOT=$(dirname "${BASH_SOURCE}")/..
cd "${ROOT}"
. test/util.sh

# travis is slow for some reason
if in_env travis; then
	export GO_TEST_TIMEOUT_SCALE=3
fi

# if we want to run this test as root, use build tag -root to ask each test...
XSUDO=''
XTAGS=()
if [[ "$@" = *"--root"* ]]; then
	if ! timeout 1s sudo -A true; then
		echo "sudo disabled: can't run as root"
		exit 1
	fi
	XSUDO='sudo -E'
	XTAGS+=('root')
fi

# As per https://github.com/travis-ci/docs-travis-ci-com/blob/master/user/docker.md
# Docker is not supported on Travis macOS test instances.
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
	XTAGS+=('nodocker')
fi

failures=''
function run-test()
{
	$XSUDO $@ -tags="${XTAGS[*]}" || failures=$( [ -n "$failures" ] && echo "$failures\\n$@" || echo "$@" )
}

# NOTE: you can run `go test` with the -tags flag to skip certain tests, eg:
# go test -tags nodocker github.com/purpleidea/mgmt/engine/resources -v
base=$(go list .)
if [[ "$@" = *"--integration"* ]]; then
	if [[ "$@" = *"--race"* ]]; then
		# adding -count=1 replaces the GOCACHE=off fix that was removed
		run-test go test -count=1 -race "${base}/integration" -v
	else
		run-test go test -count=1 "${base}/integration" -v
	fi
else
	base=$(go list .)
	packages=()
	# Split packages into groups for parallel CI execution
	# Group 1: larger/slower packages (lang, engine/resources, engine/graph, etcd)
	group1="engine/resources engine/graph lang etcd"
	# Group 2: everything else
	group2="cli converger engine/util engine/graph/autogroup engine/local engine/resources/packagekit etcd/fs etcd/util lang/ast lang/core lang/core/convert lang/core/datetime lang/core/fmt lang/core/math lang/core/net lang/core/regexp lang/format lang/types lang/funcs lang/inputs lang/parser lang/interpolate lang/interpret lib misc pgp pgraph prometheus scheduler setup tools util util/errwrap util/gettext util/grow util/password util/pprof util/recwatch util/safepath util/semaphore util/signals util/socketset util/sshutil yamlgraph"
	
	if [[ -n "$TEST_GROUP" ]]; then
		case "$TEST_GROUP" in
			1) packages=($(echo $group1 | xargs -n1 | sed "s|^|${base}/|"));;
			2) packages=($(echo $group2 | xargs -n1 | sed "s|^|${base}/|"));;
			*) echo "Unknown TEST_GROUP, running all";;  
		esac
	else
		packages=($(go list -e ./... | grep -v "^${base}/vendor/" | grep -v "^${base}/examples/" | grep -v "^${base}/test/" | grep -v "^${base}/old" | grep -v "^${base}/old/" | grep -v "^${base}/tmp" | grep -v "^${base}/tmp/" | grep -v "^${base}/integration"))
	fi
	
	if [[ "$@" = *"--integration"* ]]; then
		if [[ "$@" = *"--race"* ]]; then
			run-test go test -count=1 -race "${base}/integration" -v
		else
			run-test go test -count=1 "${base}/integration" -v
		fi
	else
		for pkg in "${packages[@]}"; do
			[ -z "$pkg" ] && continue
			echo -e "\ttesting: $pkg"
			
			if [ "$pkg" = "${base}/engine/resources/http_server_ui" ]; then
				continue # skip this special main package
			fi
			
			if [[ "$@" = *"--race"* ]]; then
				if [ "$pkg" = "${base}/lang" ]; then
					for sub in `go test "${base}/lang" -list Test`; do
						if [ "$sub" = "ok" ]; then break; fi
						echo -e "\t\tsub-testing: $sub"
						run-test go test -count=1 -race "$pkg" -run "$sub"
					done
				else
					run-test go test -count=1 -race "$pkg"
				fi
			else
				if [ "$pkg" = "${base}/lang" ]; then
					for sub in `go test "${base}/lang" -list Test`; do
						if [ "$sub" = "ok" ]; then break; fi
						echo -e "\t\tsub-testing: $sub"
						run-test go test -count=1 "$pkg" -run "$sub"
					done
				else
					run-test go test -count=1 "$pkg"
				fi
			fi
		done
	fi
fi

if [[ -n "$failures" ]]; then
	echo 'FAIL'
	echo 'The following `go test` runs have failed:'
	echo -e "$failures"
	echo
	exit 1
fi
echo 'PASS'
