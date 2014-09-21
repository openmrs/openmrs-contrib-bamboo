#!/bin/bash

## Executes a maven release prepare perform 

set -e

RELEASE_VERSION=""
DEV_VERSION=""

help(){
    echo -e "\n[HELP]"
    echo "Script to execute maven releases"
    echo "Usage: `basename $0` -r release-version -d development-version [-h]"
    echo -e "\t-h: print this help message"
    echo -e "\t-r release-version: version to be released"
    echo -e "\t-d development-version: next SNAPSHOT version"
}

test_environment(){
	if git tag | egrep -q "\-${RELEASE_VERSION}$"; then
	    echo "[ERROR] Tag ${RELEASE_VERSION} already exists in the repo. Delete it before we can continue with the process."
	    exit 1
	fi 

	if [[ "$RELEASE_VERSION" == "" ]]; then 
		echo "RELEASE_VERSION = $RELEASE_VERSION"
	    echo "[ERROR] At least one command line argument is missing. See the list above for reference. " 
	    help 
	    exit 1
	fi 

	if [[ "$$MAVEN_HOME" == "" ]]; then
	    echo "[ERROR] MAVEN_HOME variable is unset. Make sure to set it using 'export MAVEN_HOME=/path/to/your/maven3/directory/'"
	    exit 1
	fi
}


ARGUMENTS_OPTS="r:d:h"

while getopts "$ARGUMENTS_OPTS" opt; do
     case $opt in
        r  ) RELEASE_VERSION=$OPTARG;;
        d  ) DEV_VERSION=$OPTARG;;
        h  ) help; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; help; exit 1;;
     esac
done

test_environment

mkdir -p ./target/tmp_repository 
ARGS="-Dmaven.repo.local=./target/tmp_repository -DreleaseVersion=$RELEASE_VERSION"
 
if [ "$DEV_VERSION" != "" ]; then
  ARGS+=" -DdevelopmentVersion=$DEV_VERSION"
fi
 
$MAVEN_HOME/bin/mvn release:prepare release:perform ${ARGS} -B