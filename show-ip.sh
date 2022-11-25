#!/bin/bash
## title        :show-ip.sh
## description  :ip, mac and routing information with clean, minimal output
## depends      :tput, tabs, echo, ip, awk, sort*
## works in     :GNU bash version 4.3.11(1) and up.
## author       :starling
## date         :20150207
## notes        :This shows ip, mac, and routing information for all active
##               interfaces. Only shows interfaces with ip addresses.
## todo         :Show specific interfaces, filter specific interfaces.

#  check for color support and set some variables.
if [[ $(tput colors) -ge 16 ]] ; then
  # blue, yellow, cyan
  colormac="\033[34m"
  colorip="\033[33m"
  colordev="\033[36m" 
  colorrst="\033[0m"
else
  colormac=""
  colorip=""
  colorrst="" 
fi

#set tab size
tabs 2

echo -e "\nActive Interfaces:"
ip -4 -d address show | \
  awk -v colm="${colormac}" -v coli="${colorip}" -v colr="${colorrst}" -v cold="${colordev}" \
    '{ 
      if ( $3 ~ /UP/   ) { printf("  %s%-18s%s\t", cold, substr($2,1, length($2)-1),colr) }
      if ( $1 ~ /link/ ) { printf("MAC: %s%s%s\t",colm,$2,colr) }
      if ( $1 ~ /inet/ ) { printf("IP: %s%s%s\n",coli,$2,colr) } 
     }'
   
echo -e "\nRouting:"
ip -4 route show | sort --key=3.6 | awk -v cold="${colordev}" -v coli="${colorip}" -v colr="${colorrst}" \
  '{
     printf("  %s%-18s%s\tvia: %s%s%s\n",coli,$1,colr,cold,$3,colr);
   } END { printf("\n"); }'  


#  as of 1.5 awk relies on the output of the ip command directly.
#    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
#    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00 promiscuity 0 minmtu 0 maxmtu 0 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 
#    inet 127.0.0.1/8 scope host lo
#       valid_lft forever preferred_lft forever
#
#  awk keys off "UP" in the <> to get the interface, "link" to get the mac,
#  and "inet" to get the IP. These happen to be in the order I was already
#  using. As long as the output from ip command is stable we should be good
#  
#  v1.2, changed interface grep to exclude ipv6 information.
#  v1.3, changed ip command to only show ipv4 and adjusted awk to parse 
#  v1.4, adjusted for shellcheck output (quoted variables in awk arg) 
#  v1.5, removed grep and redundant awk, called out sort as a dep, been there forever.
#        sort keeps the routes grouped by interface/ip. It could be removed without
#        impacting the function of the script. //20221125
