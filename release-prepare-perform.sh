#!/bin/bash

## Executes a maven release prepare perform 

set -e -v

RELEASE_VERSION=""
DEV_VERSION=""
REMOTE_REPOSITORY=${bamboo_planRepository_repositoryUrl}

help(){
    echo -e "\n[HELP]"
    echo "Script to execute maven releases"
    echo "Usage: `basename $0` -r release-version -d development-version [-h]"
    echo -e "\t-h: print this help message"
    echo -e "\t-r release-version: version to be released"
    echo -e "\t-d development-version: next SNAPSHOT version"
    echo -e "\t-r remote repository: repository to check if the tags already exist. Default to Bamboo variable bamboo_planRepository_repositoryUrl"
}

test_environment(){
    # verify if the tag exists upstream v1.0.0 or *-1.0.0
	if git ls-remote --tags origin | egrep -q "[-v]${RELEASE_VERSION}$"; then
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


ARGUMENTS_OPTS="r:d:hr:"

while getopts "$ARGUMENTS_OPTS" opt; do
     case $opt in
        r  ) RELEASE_VERSION=$OPTARG;;
        d  ) DEV_VERSION=$OPTARG;;
        r  ) REMOTE_REPOSITORY=$OPTARG;;
        h  ) help; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; help; exit 1;;
     esac
done

git remote set-url ${REMOTE_REPOSITORY}

test_environment
TEMP_FOLDER=$(mktemp -d -t release.XXXXXXX)
ARGS="-Dmaven.repo.local=$TEMP_FOLDER -DreleaseVersion=$RELEASE_VERSION"
 
if [ "$DEV_VERSION" != "" ]; then
  ARGS+=" -DdevelopmentVersion=$DEV_VERSION"
fi
 
$MAVEN_HOME/bin/mvn org.apache.maven.plugins:maven-release-plugin:2.5.1:prepare org.apache.maven.plugins:maven-release-plugin:2.5.1:perform ${ARGS} -B