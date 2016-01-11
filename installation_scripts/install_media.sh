#!/bin/sh

createISODirectory()
{
  _isoDir=${1}
  
  if [ ! -d ${_isoDir} ]
  then
    /bin/mkdir -p ${_isoDir}
  fi

  if [ ! -d ${_isoDir} ]
  then
    /usr/bin/printf "Error creating ISO directory %s\n" "${_isoDir}"
    return 1
  fi

  /usr/bin/printf "\n\nISO Directory:\n\t"
  /bin/ls -dl ${_isoDir}
  
  return 0
}

wrongMedia()
{
  /bin/cat <<_EOD_
  
  Media Error: ${1}
  
_EOD_
  pause "Media Error"
  return 0
}

isDVD()
{
  set -x
  trap 'wrongMedia "test"' EXIT
  _filename="${1}"
  _string="${2}"
  ls -l ${_filename}
  /bin/cat <<_EOD_
  
  Search for Label: ${_filename} - "${_string}"
  
_EOD_

  if [ ! -f ${_filename} ]
  then
    return 1
  fi

  egrep "${_string}" ${_filename} ; _status=${?}
  return ${_status}
  
}

isMounted()
{

  _mount=${1}
  if [ -d ${_mount} ]
  then
    
    /bin/findmnt ${_mount} ; _status=${?}
    printf "status %s\n" ${_status}
    return ${_status}
  fi
  
  return 1
}

srcDrive()
{
  /bin/findmnt ${1} | tail -1 | awk '{print $2}'
  return
}

mountMedia()
{
  trap 'wrongMedia "Error Mounting Media' EXIT
  #vrfylabel="" ; export vrfylabel
  _configFilename="/home/octt/ansible-octt/group_vars/all/octt"
  
  cdrom=$(egrep "cdrom" ${_configFilename} | \
          cut -f2 -d: | \
          cut -c 2- | \
          sed 's/^\"//' | \
          sed 's/\"$//')
          
  tmpmntdir=$(egrep "tmpmntdir" ${_configFilename} | \
              cut -f2 -d: | cut -c 2- | \
              sed 's/^\"//' | \
              sed 's/\"$//')
              
  vrfyfile=$(egrep "vrfyfile" ${_configFilename} | \
             cut -f2 -d: | \
             cut -c 2- | \
           sed 's/^\"//' | \
           sed 's/\"$//')
           
  vrfylabel=$(egrep "vrfylabel" ${_configFilename} | \
           cut -f2 -d: | \
           cut -c 2- | \
           sed "s/'//" | \
           sed "s/'$//")
           
  isodir=$(egrep "isodir" ${_configFilename} | \
           cut -f2 -d: | \
           cut -c 2- | \
           sed 's/^\"//' | \
           sed 's/\"$//')
           
  isofile=$(egrep "isofile" ${_configFilename} | \
           cut -f2 -d: | \
           cut -c 2- | \
           sed 's/^\"//' | \
           sed 's/\"$//')
           
  ubuntumnt=$(egrep "ubuntumnt" ${_configFilename} | \
              cut -f2 -d: | \
              cut -c 2- | \
              sed 's/^\"//' | \
              sed 's/\"$//')
            
  vrfyfile="${mntdir}${vrfyfile}"

  clearscreen 

  cat <<_EOD_

Configuration

    cdrom: ${cdrom}
    tmpmntdir: ${tmpmntdir}
    isodir: ${isodir}
    isofile: ${isofile}
    ubuntumnt: ${ubuntumnt}
    vrfyfile: ${vrfyfile}
    vrfylabel: ${vrfylabel}
    
_EOD_

  pause "mountMedia"

  _isMounted=1
  _isDVD=1

  pause "Status"
  while [ ${_isMounted} -ne 0 ] || [ ${_isDVD} -ne 0 ]
  do

    isMounted "/mnt" ; _isMounted=${?}
    while [ ${_isMounted} -ne 0 ]
    do
      trap 'wrongMedia "Drive not Mounted"' EXIT
      /bin/mount ${cdrom} ${tmpmntdir}
      isMounted "/mnt" ; _isMounted=${?}
    done
  
    cat<<_EOD_
  
  Drive is mounted . . .
  
_EOD_
ls /mnt/.disk
    pause "ttt"

    isDVD "${tmpmntdir}${vrfyfile}" "${vrfylabel}" ; _isDVD=${?}
    printf "IsDVD: %s\n" "${_isDVD}"

    while [ ${_isMounted} -eq 0 ] && [ ${_isDVD} -ne 0 ] 
    do
  
      if [ ${_isDVD} -ne 0 ]
      then
  
        wrongMedia "Wrong Media in Drive"
    
        umount ${tmpmntdir}

      fi
    done


  
  done
  
  return 0
}

################################################################################
# Setup stuff prior to calling main().

  # Check UID.  Must be ZERO to run this script.
  _uid=$(/usr/bin/id -u)
  


  # What directory are we running from to use as a location of reference.
  _dirname=$( cd ${0} ; pwd | \
             /bin/sed 's%/scripts/installation_scripts%%')
  
  export _dirname
  [ -n ${debug-''} ] && /usr/bin/printf "Dir: %s\n" "${_dirname}"
  
  . ${_dirname}/scripts/common_functions

  trap 'abort "Must be run as root"' EXIT
  [ ${_uid} -ne 0 ] && exit
  
trap 'abort "Mounting Ubuntu 15.10 Server Media"' EXIT
mountMedia ; _status=${?}
if [ ${_status} -ne 0 ]
then
  exit
fi

trap 'abort "Creating ISO target"' EXIT
_srcDrive=$(srcDrive /mnt)
_isoDir=/media/iso/
_isoFile=/media/iso/ubuntu-15.10-server.iso
createISODirectory ${_isoDir} ; _status=${?}
[ ${_status} -ne 0 ] && exit

dd if=${_srcDrive} of=${_isoFile}

createISODirectory /mnt2 ; _status=${?}
[ ${_status} -ne 0 ] && exit

cat >> /etc/fstab <<_EOD_
${isodir}/${isofile} ${isodir}${ubuntumnt} iso9660 ro,relatime 0 0
_EOD_

[ ! -d ${isodir}${ubuntumnt} ] && mkdir -p ${isodir}${ubuntumnt}
mount ${isodir}${ubuntumnt}

trap '' EXIT