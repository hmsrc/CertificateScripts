#HMS SSL Scripts

## Description
Basic scripts to request, install, and monitor ssl certificates in our hosting environment.
Certificate and request files are all stored in a subversion repository.  Each site certificate has a subdirectory named SITE and files named: SITE-YYYYMMDD.crt SITE-YYYYMMDD.csr, and SITE-YYYYMMDD.key.  SITE is replaced with the provided site name and the date is date at the time the files were created.  Links to the active files are maintained with SITE.crt -> SITE-YYYYMMDD.crt etc . . .


## Download
Code is available on github in [https://github.com/hmsrc](https://github.com/hmsrc)

## License
Code released under the GNU General Public License.

## Configure
* edit `certs.configure` 
* edit `expired_certificates.txt` adding site directories to ignore, 1 per line

## Usage
* ./generate-cert-request.sh -s SITE
* Once delivered, save the certificate to a file and install it with `install-cert.sh -s SITE -f file`
* edit cron job check-certs and make it active on a server with access to the certifcate directory


## Contributors

Gregory Cavanagh  <gregory_cavanagh@hms.harvard.edu>  
[Research Computing Group](http://rc.hms.harvard.edu), Harvard Medical School  


