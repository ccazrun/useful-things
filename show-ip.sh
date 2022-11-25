#!/bin/bash
## title        :show-ip.sh
## description  :ip, mac and routing information with clean, minimal output
## depends      :ip, grep, awk, tput, tabs
## works in     :GNU bash version 4.3.11(1)
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
ip -4 -d address show | grep -B1 -E "^  +inet " | \
  awk ' { if ($1=="--" ) printf("\n"); else printf("%s ",$0); } ' | \
  awk -v colm="${colormac}" -v coli="${colorip}" -v colr="${colorrst}" -v cold="${colordev}" \
    '{
       printf("  %s%-18s%s\tMAC: %s%s%s\t IP: %s%s%s\n", cold,$NF,colr,colm,$2,colr,coli,$20,colr ); 
     }'
  # first awk concats the 2 lines from grep -B1
   
echo -e "\nRouting:"
ip -4 route show | sort --key=3.6 | awk -v cold="${colordev}" -v coli="${colorip}" -v colr="${colorrst}" \
  '{
     printf("  %s%-18s%s\tvia: %s%s%s\n",coli,$1,colr,cold,$3,colr);
   } END { printf("\n"); }'  


#  output sampe of "ip address show | grep -B1 inet"  
#
#      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#      inet 127.0.0.1/8 scope host lo
#      --
#
#  awk line ' { if ($1=="--" ) printf("\n"); else printf("%s ",$0); } '
#  after the pipe through awk -- becomes a newline and the 2 lines above become one
#      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00  inet 127.0.0.1/8 scope host lo
#  v1.2, changed interface grep to exclude ipv6 information.
#  v1.3, changed ip command to only show ipv4 and adjusted awk to parse 
#  v1.4, adjusted for shellcheck output (quoted variables in awk arg)    
