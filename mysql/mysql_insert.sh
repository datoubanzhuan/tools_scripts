#!/bin/bash
mysql_login="mysql -uroot -ppassword"
i=1
while true
do
${mysql_login} -e "insert into Syslog.SystemEvents (ID,ReceivedAt,DeviceReportedTime,Priority,FromHost,Message,InfoUnitID,SyslogTag) values ("$i",NOW(),NOW(),17,'e30d72ea457b"$i"','test mysql delete for remote syslog 2 18 "$i"',1,'classifyengine-5001"$i"');"

echo $i
((i++))
done
