#!/bin/bash
# agregate <> ftp://ftp.isc.org/isc/aggregate/aggregate-1.6.tar.gz
source='https://reestr.rublacklist.net/api/ips'
via=`netstat -rn | grep ^0.0.0.0| awk '{print $2}'`
list='/etc/bird/rkn/reestr.conf'
tmp='/tmp/rkn.ips'
manual='/opt/scripts/static.cidr'
vrfy='grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}''

wget -qO- ${source}|tr \; '\n'| ${vrfy} | sort -n | uniq| sed 's/$/\/32/' > ${tmp}
cat ${manual} | sed '/^ *$/d' >> ${tmp}
/opt/scripts/aggregate < /tmp/rkn.ips | sed "s/^/route /;s/$/ via ${via};/" > ${list} && service bird reload
