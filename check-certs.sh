#!/bin/bash
#
# check-certs.sh
#
# Run from cron to check for expired certificate files
# Checks under each site directory and alerts by email
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

. ./certs.config

#
# loop over all vhost certificates, excluding those listed as expired
#
for SITE in $( find ${CHECK_PATH} \
                 -mindepth 1 \
                 -maxdepth 1 \
                 -type d \
                 -not -name ".svn" \
                 -exec basename {} \; | \
               grep -v -f ${EXPIRED} | \
               sed 's/\*/\\*/g' )
do

  SITE=$( echo -n $SITE | sed 's/\\\*/\*/g' )
  CERT_FILE="${CHECK_PATH}/${SITE}/${SITE}.crt"
  CERT_DATE=$(openssl x509 -noout -in "${CERT_FILE}" -dates | grep notAfter | sed -e 's/notAfter=//')
  CERT_DATE_ISO=$(date --date="$CERT_DATE" "+%Y-%m-%d %H:%M:%S %Z")
  CERT_DATE_SECONDS=$(date --date="$CERT_DATE" +%s)
  NOW=$(date +%s)

  if [ $((CERT_DATE_SECONDS - NOW)) -lt ${NOTIFY_SECONDS} ]; then
    DAYS=$( echo "scale=0; $((CERT_DATE_SECONDS - NOW)) / 86400" | bc )
    [ $DEBUG == "0" ] && \
      echo "The SSL certificate for ${SITE} will expire in ${DAYS} days on ${CERT_DATE_ISO}" \
        | mail -s "Renew SSL certificate for ${SITE} by ${CERT_DATE_ISO}" ${ALERT_EMAIL}
    [ $DEBUG == "1" ] && \
      echo "The SSL certificate for ${SITE} will expire in ${DAYS} days on ${CERT_DATE_ISO}"  
  fi

done
