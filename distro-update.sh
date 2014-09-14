#!/bin/bash
#Script to checkout the distro and update version a certain module 

set -e -v

PROPERTY=""
NEXT_DEV_VERSION=""
RELEASE_VERSION=""
PREPARING_DISTRO=""
SCM=""
BRANCH=""

CLONE_FOLDER="target/distribution"


help(){
    echo -e "\n[HELP]"
    echo "Script to update version in refapp distro"
    echo "Usage: `basename $0` -r release-version -d development-version -p pom-property -s scm -b branch -n update-next-snapshot (true/false) [-h]"
    echo -e "\t-h: print this help message"
    echo -e "\t-r release-version: version to be released"


read_arguments(){
	ARGUMENTS_OPTS="r:d:p:d:h"

	while getopts "$ARGUMENTS_OPTS" opt; do
	     case $opt in
	        r  ) RELEASE_VERSION=$OPTARG;;
	        d  ) DEV_VERSION=$OPTARG;;
	        p  ) PROPERTY=$OPTARG;;
			s  ) SCM=$OPTARG;;
			b  ) BRANCH=$OPTARG;;
	        n  ) PREPARING_DISTRO=$OPTARG;;
	        h  ) help; exit;;
	        \? ) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
	        :  ) echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
	        *  ) echo "Unimplemented option: -$OPTARG" >&2; help; exit 1;;
	     esac
	done
}


test_environment(){

	if [[ "$RELEASE_VERSION" == "" || "$PROPERTY" == "" || "$NEXT_DEV_VERSION" = "" || "$PREPARING_DISTRO" == "" || "$SCM" == "" || "$BRANCH" == "" ]]; then 
		echo "RELEASE_VERSION = $RELEASE_VERSION \tPROPERTY = $PROPERTY \tNEXT_DEV_VERSION = $NEXT_DEV_VERSION \t \
		PREPARING_DISTRO = $PREPARING_DISTRO\t SCM=$SCM\t BRANCH=$BRANCH"
	    echo "[ERROR] At least one command line argument is missing. See the list above for reference. " 
	    help 
	    exit 1
	fi 
}


read_arguments
test_environment


mkdir -p $CLONE_FOLDER
git clone $SCM $CLONE_FOLDER
cd $CLONE_FOLDER
git config push.default current
git checkout $BRANCH

sed -i'' -r "s|<$PROPERTY>[^<]+</$PROPERTY>|<$PROPERTY>$RELEASE</$PROPERTY>|" pom.xml
git add pom.xml
git commit -m "[Maven Release] Increasing version of $PROPERTY to $RELEASE"
git push

