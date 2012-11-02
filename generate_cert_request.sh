#!/bin/bash
#
# generate-cert-request.sh
#
#    Automate SSL certificate request generation.
#    Check requests into systemimager subversion repository.
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

Script to generate an SSL certificate request

OPTIONS:
     -h     Show this message
     -s     name of website 
     -t     RT ticket number
EOF

    exit
}


while getopts "hs:t:" flag
do
  case $flag in
    h) usage;;
    s) SITE=$OPTARG;;      
    t) TICKET=$OPTARG;;      
  esac
done

[[ -z $SITE ]] && echo "Missing \"-s site\" " && usage

#
# shared variables from config file
#
. ./certs.config


#
# check out a working copy 
#
echo "Checking out copy of systemimager overrides into $BASE_PATH/certs . . ."
svn checkout svn+ssh://${SVN_REPO_PATH} ${CERT_PATH} > /dev/null


#
# Add keys if directory already exists, fix this to prompt and create if doesnt exist
#
if [ -d ${CERT_PATH}/${SITE} ];then
    
    KEY_PATH=${CERT_PATH}/${SITE}/${SITE}-$(date +%Y%m%d).key
    CSR_PATH=${CERT_PATH}/${SITE}/${SITE}-$(date +%Y%m%d).csr
    CRT_PATH=${CERT_PATH}/${SITE}/${SITE}-$(date +%Y%m%d).crt

    openssl req -new -nodes -newkey rsa:2048 -keyout ${KEY_PATH} -out ${CSR_PATH} -subj "${SSL_SUBJECT}"

    # empty file to place certificate when it is delivered
    touch ${CRT_PATH}
    chmod 600 ${KEY_PATH} ${CSR_PATH} ${CRT_PATH}

    # check generated request
    echo "Generated files:"
    echo "${CSR_PATH}"
    echo "${KEY_PATH}"
    echo "${CRT_PATH}"
    echo ""
    echo "Subject information in the request is:"
    openssl req -in ${CSR_PATH} -text | grep Subject

else
    echo "Output directory ${CERT_PATH}/${SITE} does not exist"
    echo "Add ${SITE} to ${SVN_REPO_PATH}"
    echo "No requests generated"
    exit 1
fi

#
# Add to subversion and commit
#
svn add ${KEY_PATH}
svn add ${CSR_PATH}
svn add ${CRT_PATH}

svn commit -m "Generated SSL certificate request for ${SITE}. (#${TICKET})" ${CERT_PATH}/${SITE}

#
# Echo to STDOUT for convenience and remove tmp files
#
cat ${CSR_PATH}
rm -rf ${BASE_PATH}

exit
