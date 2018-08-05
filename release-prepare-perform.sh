#!/bin/bash

## Executes a maven release prepare perform 
## This script is intended in multiple CI tools 

set -e

RELEASE_VERSION=""
DEV_VERSION=""
REMOTE_REPOSITORY="${bamboo_planRepository_repositoryUrl}"

RELEASE_PLUGIN="org.apache.maven.plugins:maven-release-plugin:2.5.1"

echoerr() { echo "$@" 1>&2; }

help(){
    echo -e "\n[HELP]"
    echo "Script to execute maven releases"
    echo "Usage: `basename $0` -r release-version [-d development-version] [-e remote-repo] [-h]"
    echo -e "\t-h: print this help message"
    echo -e "\t-r release-version: version to be released"
    echo -e "\t-d development-version: next SNAPSHOT version"
    echo -e "\t-e remote repository: repository to check if the tags already exist. Default to Bamboo variable bamboo_planRepository_repositoryUrl"
}

test_environment(){

	if [[ "$RELEASE_VERSION" == "" || "$REMOTE_REPOSITORY" == "" ]]; then
		echoerr "RELEASE_VERSION = $RELEASE_VERSION\t REMOTE_REPOSITORY = $REMOTE_REPOSITORY"
	    echoerr "[ERROR] At least one command line argument is missing. See the list above for reference. "
	    help
	    exit 1
	fi

	if [[ "$MAVEN_HOME" == "" ]]; then
	    echoerr "[ERROR] MAVEN_HOME variable is unset. Make sure to set it using 'export MAVEN_HOME=/path/to/your/maven3/directory/'"
	    exit 1
	fi

  if [[ "$RELEASE_VERSION" != "" && ! "$RELEASE_VERSION" =~ ^([0-9]+\.){2}[0-9]+$ ]]; then
    echoerr "[ERROR] Version $RELEASE_VERSION is not semver, e.g. 4.25.0. Check http://semver.org/ "
    exit 1
  fi

  if [[ "$DEV_VERSION" != "" && ! "$DEV_VERSION" =~ ^([0-9]+\.){2}[0-9]+(-SNAPSHOT)?$ ]]; then
    echoerr "[ERROR] Version $DEV_VERSION is not semver, e.g. 4.25.0. Check http://semver.org/ "
    exit 1
  fi

  # verify if the tag exists upstream v1.0.0 or .+-1.0.0
  git remote set-url origin ${REMOTE_REPOSITORY}  # to make sure ls-remote works on Bamboo
  if git ls-remote --tags origin | egrep -q "^(.+\-|v)${RELEASE_VERSION}$"; then
      echoerr "[ERROR] Tag ${RELEASE_VERSION} already exists in the repo. Delete it before we can continue with the process."
      exit 1
  fi
}


ARGUMENTS_OPTS="r:d:hr:"

while getopts "$ARGUMENTS_OPTS" opt; do
     case $opt in
        r  ) RELEASE_VERSION=$OPTARG;;
        d  ) DEV_VERSION=$OPTARG;;
        e  ) REMOTE_REPOSITORY=$OPTARG;;
        h  ) help; exit;;
        \? ) echoerr "Unknown option: -$OPTARG"; help; exit 1;;
        :  ) echoerr "Missing option argument for -$OPTARG"; help; exit 1;;
        *  ) echoerr "Unimplemented option: -$OPTARG"; help; exit 1;;
     esac
done

test_environment
TEMP_FOLDER=$(mktemp -d -t release.XXXXXXX)
ARGS="-Dmaven.repo.local=$TEMP_FOLDER -DreleaseVersion=$RELEASE_VERSION"

if [ "$DEV_VERSION" != "" ]; then
  DEV_VERSION=${DEV_VERSION%-SNAPSHOT}-SNAPSHOT  # always add a snapshot if not there
  ARGS+=" -DdevelopmentVersion=$DEV_VERSION"
elif [[ "$RELEASE_VERSION" =~ .*\.0$ ]]; then
  # force version 2.19.0-SNAPSHOT if releasing 2.18.0
  # https://talk.openmrs.org/t/releasing-modules-using-semantic-versioning/7797/15
  VERSION_SPLIT=(${RELEASE_VERSION//./ })
  DEV_VERSION="${VERSION_SPLIT[0]}.$((${VERSION_SPLIT[1]}+1)).0-SNAPSHOT"
  ARGS+=" -DdevelopmentVersion=$DEV_VERSION"
fi

EXIT_CODE=0
echo "Calling mvn ${RELEASE_PLUGIN}:prepare ${ARGS} -B"
$MAVEN_HOME/bin/mvn ${RELEASE_PLUGIN}:prepare ${ARGS} -B || EXIT_CODE=$?
if [[ "$EXIT_CODE" != "0" ]]; then
    echoerr "[ERROR] mvn release:prepare failed. Attempting to do a release rollback. "
    $MAVEN_HOME/bin/mvn ${RELEASE_PLUGIN}:rollback ${ARGS} -B || :
    echoerr "[ERROR] mvn release:prepare failed, scroll up the logs to see the error. release:rollback was attempted. Delete the tag from the repository (if it exists), check if the SCM tag is a ssh and not http and try again. "
    exit $EXIT_CODE
fi

EXIT_CODE=0
echo "Calling mvn ${RELEASE_PLUGIN}:perform ${ARGS} -B"
$MAVEN_HOME/bin/mvn ${RELEASE_PLUGIN}:perform ${ARGS} -B || EXIT_CODE=$?
if [[ "$EXIT_CODE" != "0" ]]; then
    echoerr "[ERROR] mvn release:perform failed. Fix the problem and try another release number. "
    exit $EXIT_CODE
fi

echo "Uploading next snapshots"
$MAVEN_HOME/bin/mvn deploy -DskipTests -B
