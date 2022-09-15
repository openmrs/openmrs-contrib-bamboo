#!/bin/sh
# Variables that are passed from the bamboo deploy plan e.g. 
# scp-to-sourceforge.sh ${bamboo.build.working.directory}/target/distro openmrs.war releases/OpenMRS_Platform_${bamboo.maven.release.version} openmrs.war
sourceDir=$1
sourceFile=$2
targetDir=$3
targetFile=$4
syncDir=${sourceDir}/rsync

mkdir -p ${syncDir}/${targetDir}

cp ${sourceDir}/${sourceFile} ${syncDir}/${targetDir}/${targetFile}

# Rsync to sourceforge
rsync -avOP -e "ssh -o StrictHostKeyChecking=no -i $HOME/.ssh/sourceforge/id_ed25519" ${syncDir}/ openmrs@frs.sourceforge.net:/home/frs/project/o/op/openmrs/
