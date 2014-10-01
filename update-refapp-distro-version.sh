#!/bin/bash
# Script to checkout the distro and update version a certain module. 
# It can save the released version or next snapshot. 

set -e

PROPERTY=""
FILE_SCM=""
NEXT_VERSION=""

CLONE_FOLDER="tmp-checkout"
CURRENT_DIR=$(pwd)

help(){
    echo -e "\n[HELP]"
    echo "Script to update version of the refapp distro pom in several modules. It receives a file with a SCM url per line. "
    echo "Usage: `basename $0` -v next-version -p pom-property -f scm-lists-file [-h]"
}


test_environment(){

	if [[  "$PROPERTY" == "" || "$NEXT_VERSION" = "" || "$FILE_SCM" == "" ]]; then 
		echo "PROPERTY = $PROPERTY \tNEXT_VERSION = $NEXT_VERSION \tFILE_SCM = $FILE_SCM"
	    echo "[ERROR] At least one command line argument is missing. See the list above for reference. " 
	    help 
	    exit 1
	fi 
}

ARGUMENTS_OPTS="v:p:f:h"

while getopts "$ARGUMENTS_OPTS" opt; do
     case $opt in
        v  ) NEXT_VERSION=$OPTARG;;
        p  ) PROPERTY=$OPTARG;;
        f  ) FILE_SCM=$OPTARG;;
        h  ) help; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; help; exit 1;;
     esac
done
	
test_environment

rm -rf target
mkdir -p target
ERRORS=""
SUCCESS=""

while read SCM; do 
  echo -e "\n[INFO] Trying to update $SCM"
  ( 
	CLONE_FOLDER=target/$( sed -E "s|[^/]*/(.*)\.git|\1|" <<< "$SCM")
	git clone $SCM $CLONE_FOLDER
	cd $CLONE_FOLDER
	git config push.default current

	sed -i'' -E "s|<$PROPERTY>[^<]+</$PROPERTY>|<$PROPERTY>$NEXT_VERSION</$PROPERTY>|" pom.xml
	git add pom.xml
	git commit -m "[Maven Release] Upgrading refapp pom to $NEXT_VERSION"

	git push
  ) 

  if [[ "$?" == "0" ]]; then
  	  echo "[INFO] Success updating $SCM"
  	  SUCCESS+="\n\t - $SCM"
  else
  	  echo "[ERROR] Repository $SCM couldn't be updated"
  	  ERRORS+="\n\t - $SCM"
  fi
done < "$FILE_SCM"

echo -e "\n[INFO] The following repositories were updated successfully: $SUCCESS\n"


if [[ "$ERRORS" != "" ]]; then
	echo -e "[ERROR] The following repositories could not be updated: $ERRORS\nUpdate them manually. "
	exit 1
fi
