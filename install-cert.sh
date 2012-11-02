#!/bin/bash
#
# install-cert.sh
#
#    Copyright 2008-2012 Gregory Cavanagh 
#    Research Computing, Harvard Medical School
#    gregory_cavanagh@hms.harvard.edu
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

usage(){
    cat <<EOF

usage: $0 options

Script to update an SSL certificate

OPTIONS:
     -h     Show this message
     -d     YYYYMMDD to use for linking, indicating www.eagle-i.org-20101107 for example
            Default is to use the most recent
     -f     path to the crt certificate file to be installed
     -s     name of website 
     -t     RT ticket number
EOF

    exit
}


while getopts "hd:f:s:t:" flag
do
  case $flag in
    h) usage;;
    d) CERT_DATE=$OPTARG;;
    f) CRT_FILE=$OPTARG;;
    s) SITE=$OPTARG;;      
    t) TICKET=$OPTARG;;  
  esac
done

[[ -z $CRT_FILE ]] && echo "Missing \"-f crt_file\" " && usage
[[ ! -f $CRT_FILE ]] && echo "Cert file ${CRT_FILE} does not exist " && usage
[[ -z $SITE ]] && echo "Missing \"-s site\" " && usage
#[[ -z $TICKET ]] && echo "Missing \"-t ticket_number\" " && usage

#
# include variables from shared config file
. ./certs.config

#
#
# check out a working copy in a safe temporary directory
#
echo "Checking out copy of systemimager overrides into ${CERT_PATH} . . ."
svn checkout svn+ssh://${SVN_REPO_PATH}/${SITE} ${CERT_PATH} > /dev/null

#
# Exit if request files not present
#
if ls -lrt ${CERT_PATH}/${SITE}-* &> /dev/null; then
    echo "files do exist"

    #
    # find the date string for the matching cert request
    #
    if [ -z ${CERT_DATE} ]; then
	ls -lrt ${CERT_PATH}/${SITE}-*
	CERT_DATE=$(ls -rt ${CERT_PATH}/${SITE}-* | head -n 1 | sed -e 's/\// /g' |  awk '{ f=$NF }; END{ print f }' | sed -e 's/.*-//' -e 's/\..*//')
	echo
    fi

    read -p "Use certificate files with date $CERT_DATE? (N/y)" -n 1
    if [ "$REPLY" != "y" ];then
	echo "Aborting"
	exit 1
    fi

else
    echo "Exiting: No cert request files found."
    exit 1
fi


#
# remove old links
#
echo
rm -v ${CERT_PATH}/${SITE}.csr ${CERT_PATH}/${SITE}.key ${CERT_PATH}/${SITE}.crt

#
#copy certificate file
#
cp -v  ${CRT_FILE}  ${CERT_PATH}/${SITE}-${CERT_DATE}.crt

#
#make new links
#
cd ${CERT_PATH}
ln -v -s ./${SITE}-${CERT_DATE}.csr ./${SITE}.csr
ln -v -s ./${SITE}-${CERT_DATE}.key ./${SITE}.key
ln -v -s ./${SITE}-${CERT_DATE}.crt ./${SITE}.crt

#
# svn commit changes
#
svn add ${CERT_PATH}/*
svn commit -m "Added SSL certificate for ${SITE}. (#${TICKET})" ${CERT_PATH}

#
# cleanup
#
rm -rf ${CERT_PATH}

#
# Add custom post install steps here
#
echo "Install complete"
exit
