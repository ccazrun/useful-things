#!/bin/bash
#  get-certificate-json.sh - return certificate details as json
#  tested in bash version: 5.0.17
#  
#  DEPENDS
#    openssl, sed, jq
#
#  OPTIONS
#    -d [domain to check] (Mandatory)
#    -p [port to connect] (default 443)
#    -c                   compact output  (default: no)
#    -s                   Silent  (default: no)
#    -h                   This help
#
#  DESCRIPTION
#    This script will grab certificates via openssl s_client and output
#    a json structure with certifcate details including:
#
#      1. number of days to expire, not before date, not after date
#      2. issuer details (authority key id, issuer common name, country, org)
#      3. subject details (subject key id, subject common name, names, sans)
#      4. certifcate serial
#    
#  
#  EXAMPLES
#  ${SCRIPT_NAME} -d google.com           google.com:443 pretty output
#  ${SCRIPT_NAME} -d google.com -p 443    google.com:443 pretty output
#  ${SCRIPT_NAME} -d google.com -p 443 -c google.com:443 compact output
#  domain (-d) is mandatory, port (-p) defaults to 443
#  compact output is enabled with the flag -c
#  help is displayed with -h 
#
#  HEADER END
#  SCRIPT BODY
domain=example.com
port=443
compact=false
silent=false
opensslx509opts="-inform pem -noout -text -certopt no_sigdump,no_header,no_version,no_signame,no_pubkey,no_aux"

messagevalue="OK"



#  SUPPORT FUNCTIONS 
#function print-scriptinfo() {
print_scriptinfo() {
  #  uses only builtins
  #  prints this file to the first line starting with "#  HEADER END"
  mapfile < "$0" inlines
  pattern="^#  HEADER END"
  for i in "${!inlines[@]}"; do
    if [[ "${inlines[$i]}" =~ ${pattern} ]] ; then
      stopline=${i}
      break 2
    fi
  done
  echo "SCRIPT INFO:" 
  for (( i=1; i<$stopline; i++)); do
    printf  " ${inlines[$i]###}"
  done
}

#function print-error() {
print_error() {
  #  uses only builtins
  #  error strings array
  errorlist=( 
    "Domain not provided. Execution aborted."
    "Domain provided has invalid characters. Execution aborted."
    "Domain provided does not appear valid. Execution aborted."
    "Domain provided has too many characters. Execution aborted."
    "Certificate not grabbed from ${domain}:${port} execution aborted. (No cert or NXDomain)"
    "Port is not a number or not in the range of 1-65535"
  )
  showhelp=false
  case "${1}" in
    domnotprovided) messagevalue=${errorlist[0]}; showhelp=true ;;
    dominvalidchar) messagevalue=${errorlist[1]};;
    dominvalidfqdn) messagevalue=${errorlist[2]};;
    dominvalidlong) messagevalue=${errorlist[3]};;
    certnotreceive) messagevalue=${errorlist[4]};;
    portnuminvalid) messagevalue=${errorlist[5]};;
    *) messagevalue="Undefined Error. Execution Aborted" ;;
  esac
  
  if [ "${silent}" == "true" ] ; then # running unattended
     echo '{ "message" : "'${messagevalue}'" }'
  else 
     if [ ${showhelp} == "true" ] ; then
       print_scriptinfo
     fi
     echo ${messagevalue}
  fi
  exit 1
}

# process arguments:
while getopts cd:hp:sn flag
do 
  case "${flag}" in
    c) compact=true;;
    d) domain=${OPTARG};;
    n) PATH=$PATH:/usr/local/bin:/opt/bin:/bin;;
    p) port=${OPTARG};;
    s) silent=true;;
    h) print-scriptinfo; exit 0 ;;
  esac
done

#  Sanity checks
#  1. check to see if the domain is still example.com.
if [ "${domain}" == "example.com" ] ; then
  print_error "domnotprovided"
  #echo "No domain provided! Help displayed and execution aborted."
  #exit 1;
  
fi

#  Domain check 1: only characters  [a-zA-Z0-9.-] letters numbers hyphen and dot
if ! [ $(echo ${domain} | sed -E "s/^[a-zA-Z0-9.-]+$/allvalidchar/") == "allvalidchar" ] ; then #domain has bad chars
  print_error "dominvalidchar"
  #echo "Domain provided has invalid characters. Execution aborted."
  #exit 1;  
fi

#  Domain Check 2: must have at least one dot not in first or last postition
#  Domain Check 3: hyphen cannot be first or last character if present
if ! [ $(echo ${domain} | \
  sed -E 's/^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$/possibledomain/') == "possibledomain" \
 ]  ; then # domain does not fit convention
    print_error "dominvalidfqdn"
    #echo "Domain provided does not appear valid. Execution aborted."
    #exit 1;
fi
 
#  Domain Check 4: not longer than 255 characters
if [ ${#domain} -gt "255" ] ; then # domain too long
   print_error "dominvalidlong"
   #echo "Domain provided has too many characters. Execution aborted."
   #exit 1;
fi

#  Domain Check 5: Look it up
#  this check is redundant if you supress openssl errors and check the length
#  of the certificategrab variable before processing.

if [ "${compact}" == "true" ] ; then
  jqopts="--sort-keys -c"
else
  jqopts="--sort-keys"
fi

#  Port check 1: is it numeric
if ! [ $( echo ${port} | sed -E 's/^[0-9]+$/isnumbers/' ) == "isnumbers" ] ; then #not just numbers
  print_error "portnuminvalid"
fi

#  Port check 2: Valid port number?
if ! [ ${port} -gt 0  -a  ${port} -lt 65536 ] ; then #not a valid port
  print_error "portnuminvalid"
fi

#  Begin Processing

# grab the cert to process
certificategrab=$( echo "" | \
   openssl s_client -showcerts \
     -servername ${domain} \
     -connect ${domain}:${port} 2>/dev/null | \
   openssl x509 ${opensslx509opts} 2>/dev/null \
 )

# check to see that something is in certificategrab (may not be valid)
if [ ${#certificategrab} -lt 1024 ] ; then
  print_error "certnotreceive"
fi

# process that cert (ugly, but it works in most situations)
echo "${certificategrab}" | \
  sed -En -e 's/\s+(Serial Number: .*) \(.*\)/\1/p' \
          -e '/^\s+Serial Number:\s*$/{N;s/\n/ /g;p;d}' \
          -e '/^\s+Not/p' \
          -e '/^\s+Subject/p' \
          -e '/^\s+X509v3 Sub/{N;s/\n/ /g;p;d}' \
          -e '/^\s+keyid/p' \
          -e '/^\s+Issuer:/p' | \
   sed -E -e '/Subject:/{h;d};${p;g}' | \
   sed -E -e '/Alternative/{h;d};${p;g}' \
          -e 's/DNS:|IP Address://g' | \
   sed -E -e 's/ = /=/g' \
          -e 's/\s\s\s+//g' \
          -e 's/, /,/g' \
          -e '/Subject Alternative Name/p;' \
          -e 's/X509v3 Subject Alternative Name:/"sans":["/g' | \
   sed -E -e '/Serial Number:/s/Serial Number:\s*(.*)/"serial_number":"\1"/'\
          -e '/Not Before/s/Not Before:\s*(.*)/"not_before":"\1"/' \
          -e '/Not After/s/Not After\s*:\s*(.*)/"not_after":"\1"/' \
          -e '/Subject Key/s/.*fier:(.*)/"subject_key_id":"\1"/' \
          -e 's/Subject.*CN=(.*)/"subject":{"common_name":"\1","names":[/' \
          -e 's/(Issuer:.*)ST=.*,L=/\1L=/' \
          -e 's/(Issuer:.*)L=.*,O=/\1O=/' \
          -e 's/(Issuer:.*),OU=.*,CN=(.*),.*/\1,CN=\2/' \
          -e 's/keyid:(.*)/"authority_key_id":"\1"/' \
          -e '/X509v3 Subject/{s/X509v3 Subject.*:/"/;s/,/","/g;s/$/"]},/}' \
          -e '/"sans"/{s/,/","/g;s/$/"]/}' \
          -e '/Issuer/s/.*C=(.*),O=(.*),CN=(.*)/"issuer":{"country":"\1","organization":"\2","common_name":"\3"}/' | \
   sed -E -e '/"subject"/{N;s/\n/ /g;p;d}' \
          -e '$a}' \
          -e '1i{' \
          -e '$n; s/$/,/' | \
   sed -E -e 's/""/"/g' | \
   jq ${jqopts} '.not_before |= (strptime("%b %d %H:%M:%S %Y GMT") | todateiso8601) 
        | .not_after |= (strptime("%b %d %H:%M:%S %Y GMT") | todateiso8601) 
        | . + {"days_remaining": ((((.not_after | fromdateiso8601) - now ) 
        /86400) | floor) } | . + { "message": "OK" } '
        
#  FOOTER START
#  version   1.3
#  author    Starling
#  copyright 2022-04-09
#  license   CC BY-SA
#  1.0 initial
#  1.1 sed string changes.
#  1.2 2022-06-11, 
#    a. added final scrub for repeating double quotes causing jq error on some certs.
#    (e.g. Cloudflare tested on allaboutcookies.org)
#    b. completed version 1 of domain validity checks and cert length checks (hard fail, exit 1)
#    c. added message property with a value of OK on success
#  1.3 2022-07-31,
#    a. added port number checks
#    b. some reformatting
#  inspired by: 
#      https://prefetch.net/blog/2019/12/10/converting-x509-certificates-to-json-objects/
#      and the certinfo tool from cloudflare.
