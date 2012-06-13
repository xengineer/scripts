#!/bin/sh -e

## anything in this file gets run AFTER the mirror has been run
## put your custom post mirror operations in here ( like rsyncing the installer files and running clean.sh automaticly )

## Example of grabbing the extra translations and installer files from ubuntu ( note rsync needs to be installed 
## and in the path for this example to work correctly )

#################
#
# define binaries
#

ECHO="/bin/echo"
DATE=`/bin/date '+%Y%m%d'`
COPY="/bin/cp -prf"
LN="/bin/ln -s"
RSYNC="/usr/bin/rsync"
AMGENCTRL="/usr/local/sbin/amgenctrl.rb"
MKDIR="/bin/mkdir"

#################
#
# define constants
#

REPODIR="/mnt/external/repository"
REPOTMP="/mnt/external/repository_tmp"
REPODATE=`${ECHO} ${REPODIR}${DATE}`
CODENAME="precise"

SYNCURL="ftp.riken.go.jp"
RSYNCSOURCE="rsync://${SYNCURL}/ubuntu/"
BASEDIR="${REPOTMP}/mirror/${SYNCURL}/Linux/ubuntu/dists/${CODENAME}/"
BASEDIR_UPDATES="${REPOTMP}/mirror/${SYNCURL}/Linux/ubuntu/dists/${CODENAME}-updates/"
BASEDIR_SECURITY="${REPOTMP}/mirror/${SYNCURL}/Linux/ubuntu/dists/${CODENAME}-security/"

#################
#
# main(rsync)
#

${ECHO} "######################################"
${ECHO} "# Starting post process shell script #"
${ECHO} "######################################"
date '+%Y-%m-%d-%H:%M:%S'
${ECHO} "running rsync... ${RSYNCSOURCE}/dists/${CODENAME}"
${RSYNC} --recursive --times --links --hard-links \
      --exclude "Packages*" --exclude "Sources*" --exclude "Release*" --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}/ ${BASEDIR}

${RSYNC} --recursive --times --links --hard-links --delete --delete-after --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}/ ${BASEDIR}

${ECHO} "running rsync... ${RSYNCSOURCE}/dists/${CODENAME}-updates"
${RSYNC} --recursive --times --links --hard-links \
      --exclude "Packages*" --exclude "Sources*" --exclude "Release*" --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}-updates/ ${BASEDIR_UPDATES}

${RSYNC} --recursive --times --links --hard-links --delete --delete-after --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}-updates/ ${BASEDIR_UPDATES}

${ECHO} "running rsync... ${RSYNCSOURCE}/dists/${CODENAME}-security"
${RSYNC} --recursive --times --links --hard-links \
      --exclude "Packages*" --exclude "Sources*" --exclude "Release*" --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}-security/ ${BASEDIR_SECURITY}

${RSYNC} --recursive --times --links --hard-links --delete --delete-after --no-motd \
      ${RSYNCSOURCE}/dists/${CODENAME}-security/ ${BASEDIR_SECURITY}

${ECHO}
# move directory
if [ -d ${REPODATE} ];then
  ${ECHO} "Overwriting repository ${REPODATE}"
  ${ECHO} ${RSYNC} -avr ${REPOTMP}/* ${REPODATE}
  ${RSYNC} -avr ${REPOTMP}/* ${REPODATE} | pv > /dev/null 
else
  ${ECHO} "${MKDIR} ${REPODATE}"
  ${MKDIR} ${REPODATE}
  ${ECHO} ${RSYNC} -avr ${REPOTMP}/* ${REPODATE}
  ${RSYNC} -avr ${REPOTMP}/* ${REPODATE} | pv > /dev/null
fi

# make an symbolic link
# its easier to take a backup this way
${ECHO}
if [ ! -h ${REPODIR} ];then
  ${ECHO} ${LN} ${REPODATE} ${REPODIR}
  ${LN} ${REPODATE} ${REPODIR}
fi

# execute generation control script
${AMGENCTRL} -y >> /tmp/genctrl.log

if [ $? -ne 0 ];then
  ${ECHO} "${AMGENCTRL} did not run correctly. Check /tmp/genctrl.log"
fi
${ECHO} "Current repository is ${REPODATE}"
