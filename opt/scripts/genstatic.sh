#!/bin/bash
result='/opt/scripts/static.cidr'
echo '' > ${result}
for i in $( ls /etc/bird/rkn/*.conf | grep -v reestr ); do
        echo "#####${i}" >> ${result}
        cat ${i} | awk '{print $2}' >> ${result}
done

