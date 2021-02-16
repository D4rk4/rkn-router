#!/bin/bash
# agregate <> ftp://ftp.isc.org/isc/aggregate/aggregate-1.6.tar.gz
git='https://github.com/zapret-info/z-i.git'
# docker run -itd --name my-iptoasn -p 80:53661 ilyaglow/iptoasn-webservice
IP2ASN='http://127.0.0.1/v1/as/ip'
aggr='/opt/scripts/aggregate -q'
out='/opt/scripts/autodiscover.cidr'
reestr='/etc/bird/rkn/reestr.conf'
tmp='/tmp/rkn.ips'
try='0'
###
main () {
	via=`netstat -rn | grep ^0.0.0.0| awk '{print $2}'|head -1`
	stage1;
	info;
	compact;
	echo configure | /usr/sbin/birdc > /dev/null
}
###
info () {
	echo "Lastest processed IP: ${singleIP}"
	echo "Lastest added ISP: `grep \# ${out}| sed s/#//g | tail -1`"
	echo "Dirty routes: `cat ${reestr} | grep /3 | wc -l`"
	echo "Total routes: `cat ${reestr} |wc -l`"
}
###
compact () {
	mv ${out} ${out}.save
	awk '!x[$0]++' ${out}.save > ${out}
}
###
iptoasncom () {
	wget -qO- "${IP2ASN}/${singleIP}" | jq .as_description | sed 's/"//g;s/^/###/g'  >> ${out}
	wget -qO- "${IP2ASN}/${singleIP}" | jq .first_ip,.last_ip | tr '\n' '-' | sed 's/-$//;s/"//g' |\
	xargs -I '{}' bash -c 'ipcalc -rn {} | tail -n +2' | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -vE '^192\.168\.'  >> ${out}
	genroutes;
}
###
stage1 () {
	try=$((try + 1))
	if [ ${try} -eq 100 ]; then
		genroutes;
		exit 0;
	fi
	singleIP=`cat ${reestr} | grep /3 | shuf -n 1 | awk '{print $2}' | cut -f1 -d/`
	iptoasncom;
  # Loop for first time aggregation
	#stage1;
}
###
genroutes () {
	git -C /tmp/z-i/ pull || git clone https://github.com/zapret-info/z-i.git /tmp/z-i/
	cd /tmp/z-i/ && git gc --auto
	cat /tmp/z-i/dump.csv | cut -f 1 -d\; | tr '|' '\n' | sed 's/ //g' | grep -vE '(Updated|\:)' | sed 's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}$/&\/32/p' | sort -nr | uniq > ${tmp}
	cat ${out} | grep -v \#| sed '/^ *$/d' >> ${tmp}
	${aggr} < ${tmp} | sed "s/^/route /;s/$/ via ${via};/" > ${reestr} 
}

main;
