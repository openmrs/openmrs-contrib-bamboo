#!/bin/bash
# Script to checkout the distro and update version a certain module. 
# It can save the released version or next snapshot. 

set -e

PROPERTY=""
NEXT_DEV_VERSION=""
RELEASE_VERSION=""
PREPARING_DISTRO=""
SCM=""
BRANCH=""

CLONE_FOLDER="target/distribution"
CURRENT_DIR=$(pwd)

echoerr() { echo "$@" 1>&2; }

help(){
    echo -e "\n[HELP]"
    echo "Script to update version in refapp distro"
    echo "Usage: `basename $0` -r release-version -d development-version -p pom-property -s scm -b branch -n update-next-snapshot (true/false) [-h]"
    echo -e "\t-h: print this help message"
    echo -e "\t-r release-version: version to be released"
}


test_environment(){

	if [[ "$RELEASE_VERSION" == "" || "$PROPERTY" == "" || "$NEXT_DEV_VERSION" = "" || "$PREPARING_DISTRO" == "" || "$SCM" == "" || "$BRANCH" == "" ]]; then 
		echoerr "RELEASE_VERSION = $RELEASE_VERSION \tPROPERTY = $PROPERTY \tNEXT_DEV_VERSION = $NEXT_DEV_VERSION \t \
		PREPARING_DISTRO = $PREPARING_DISTRO\t SCM=$SCM\t BRANCH=$BRANCH"
	    echoerr "[ERROR] At least one command line argument is missing. See the list above for reference. " 
	    help 
	    exit 1
	fi 

	if [[ "$$MAVEN_HOME" == "" ]]; then
	    echoerr "[ERROR] MAVEN_HOME variable is unset. Make sure to set it using 'export MAVEN_HOME=/path/to/your/maven3/directory/'"
	    exit 1
	fi
}

ARGUMENTS_OPTS="r:d:p:s:b:n:h"

while getopts "$ARGUMENTS_OPTS" opt; do
     case $opt in
        r  ) RELEASE_VERSION=$OPTARG;;
        d  ) NEXT_DEV_VERSION=$OPTARG;;
        p  ) PROPERTY=$OPTARG;;
		s  ) SCM=$OPTARG;;
		b  ) BRANCH=$OPTARG;;
        n  ) PREPARING_DISTRO=$OPTARG;;
        h  ) help; exit;;
        \? ) echoerr "Unknown option: -$OPTARG"; help; exit 1;;
        :  ) echoerr "Missing option argument for -$OPTARG"; help; exit 1;;
        *  ) echoerr "Unimplemented option: -$OPTARG"; help; exit 1;;
     esac
done
	
test_environment

# If preparing a refapp distro release, commit the released version. Otherwise, next snapshot
UPDATE_RELEASE=""
if [[ "$PREPARING_DISTRO" == "true" ]]; then
	UPDATE_RELEASE="$RELEASE_VERSION"
else
	UPDATE_RELEASE="$NEXT_DEV_VERSION"
fi


mkdir -p $CLONE_FOLDER
git clone $SCM $CLONE_FOLDER
cd $CLONE_FOLDER
git config push.default current
git checkout $BRANCH

if ! egrep -q "<$PROPERTY>[^<]+</$PROPERTY>" pom.xml; then
	echoerr "[ERROR] Property $PROPERTY does not exist in the distro pom $SCM. It cannot be updated"
	exit 1
fi

sed -i'' -r "s|<$PROPERTY>[^<]+</$PROPERTY>|<$PROPERTY>$UPDATE_RELEASE</$PROPERTY>|" pom.xml

# git diff-tree is always returning 1 in the Bamboo agents :/ Using git diff instead
if [[ -z $(git diff) ]]; then
	echoerr "[WARN] Property $PROPERTY was already set to $UPDATE_RELEASE. Skipping commit."
	exit 0
fi

git add pom.xml
git commit -m "[Maven Release] Increasing version of $PROPERTY to $UPDATE_RELEASE"

# When commiting a SNAPSHOT to the distro, make sure it's already deployed
if [[ "$PREPARING_DISTRO" != "true" ]]; then
	(   
		cd $CURRENT_DIR
	    $MAVEN_HOME/bin/mvn deploy -DskipTests -B 
	)
fi

git push

