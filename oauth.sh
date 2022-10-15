#!/bin/bash
# expects files to be in $CONFIGDIR
# first argument is used as a filename in $CONFIGDIR
# TODO: error checking code. particularly argument count and case
# requires: oathtool



CONFIGPATH=~/.otp/
CONFIGFILE=$1

### should not have to edit below this line ###

o_key=""  #secret key
o_type="" #type of otp, default is HOTP (HOTP|TOTP)
o_encode="" #secret key encoding default is hex encode. (BASE32|HEX)
o_algorithm="" #default mac algorithm for is hmac-sha1. (HMAC−SHA256|HMAC−SHA512|HMAC-SHA1) 
o_digits="" #number of digits in code, default is 6
o_step="" #time step (default is 30s)

OATHOPTS=""

main() {
  
  if [ "$CONFIGFILE" == "" -o "$CONFIGFILE" == "*" ] 
    then
      ACCOUNTS="*"
      echo ""
      for a in $CONFIGPATH$ACCOUNTS
      do
        #give me just the filename, no path
        CONFIGFILE="${a##*/}"
        OATHOPTS=""
        get_account
        set_options
  
        printf "%-20s : " "$CONFIGFILE"
        oathtool $OATHOPTS $o_key
        #echo "" 
      done
    else
      get_account
      set_options
  
      printf "\n%-20s : " "$CONFIGFILE"
      oathtool $OATHOPTS $o_key 
  fi
  echo "" 
}

get_account() {
  i=0
  while read line; do
    if [[ "$line" =~ ^[^#]*= ]]; then
      name[$i]=${line%%=*}
      value[$i]=${line#*=}
      ((i++))
    fi
  done < $CONFIGPATH/$CONFIGFILE

  #set our params, use the key in name[] to set our variables
  n=0
  until [ $n -eq ${#name[@]} ]; do
    item=${name[$n]}
    case "$item" in
      okey)
        o_key=${value[$n]}
        ;;
      otype)
        o_type=${value[$n]}
        ;;
      oencode)
        o_encode=${value[$n]}
        ;;
      oalgorithm)
        o_algorithm=${value[$n]}
        ;;
      odigits)
        o_digits=${value[$n]}
        ;;
      ostep)
        o_step=${value[$n]}
        ;;
      *)
        ;;
    esac
    let n+=1
  done
}

set_options() {
  #a bunch of ifs to set up the command line options for oathtool
  #hex encoded secret is default.
  if [ "$o_encode" == "base32" ]; then
    OATHOPTS+="--base32 "
  fi
  
  if [ "$o_type" == "totp" ]; then
    #totp mode default is sha1 (hmac-sha1)
    if  [ "$o_algorithm" == "" ] || [ $o_algorithm == "hmac-sha1" ]; then
      OATHOPTS+="--totp "
    elif [ "$o_algorithm" == "hmac-sha256" ]; then
      OATHOPTS+="--totp=sha256 "
    elif [ "$o_algorithm" == "hmac-sha512" ]; then
      OATHOPTS+="--totp=sha512 "
    else
      #nothing... this should throw an error.
      OATHOPTS+=""
    fi
    
    #step only matters in totp defaults to 30, (only set when you have to)
    if [ "$o_step" != "" ] && [ "$o_step" != "30" ]; then
      OATHOPTS+="--time-step-size=$o_step "
    fi
  fi
  
  if [ "$o_digits" != "" ] && [ "$o_digits" != "6" ]; then
    OATHOPTS+="--digits=$o_digits "
  fi
}

main
