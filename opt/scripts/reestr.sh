#!/bin/bash
# agregate <> ftp://ftp.isc.org/isc/aggregate/aggregate-1.6.tar.gz
source='https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv'
via=`netstat -rn | grep ^0.0.0.0| awk '{print $2}'`
list='/etc/bird/rkn/reestr.conf'
tmp='/tmp/rkn.ips'
manual='/opt/scripts/static.cidr'

wget -qO- ${source}| cut -f 1 -d\; | tr '|' '\n' | sed 's/ //g' | sort -nr | uniq  | grep -v Updated | sed 's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}$/&\/32/p' > ${tmp}
cat ${manual} | sed '/^ *$/d' >> ${tmp}
/opt/scripts/aggregate < /tmp/rkn.ips | sed "s/^/route /;s/$/ via ${via};/" > ${list} && service bird reload
