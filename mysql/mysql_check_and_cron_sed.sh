#!/bin/bash

if [ ! -f /run.flag ]; then
    # config ntp; the docker must add --privileged, otherwise the ntpdate and hwclock can't work
    if [ -z "$NTP_SERVER" ]; then
        export NTP_SERVER="ntp.aliyun.com"
    fi
    touch /var/spool/cron/crontabs/root

    (
        crontab -l
        echo "0 1 * * * /usr/sbin/ntpdate ${NTP_SERVER}"
    ) | crontab

    # config DB Keep time(day)
    if [ -z "$KEEP_DAYS" ]; then
        export KEEP_DAYS=30
    fi
    time_seconds=$((KEEP_DAYS * 24 * 3600))
    sed -i "s/\${PHP_DELETE_TIME}/${time_seconds}/g" /maintenance.sh

    (
        crontab -l
        echo "0 0 * * * /maintenance.sh"
    ) | crontab
fi

# start crontab
/usr/sbin/cron

# run mysql
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    export MYSQL_ROOT_PASSWORD="Password"
fi

/docker-entrypoint.sh "$@"

# check whether mysql is up or not
while true; do
    TMP=$(mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} status 2>&1 | head -n 1 | cut -f1 -d:)
    case ${TMP} in
    Uptime)
        break
        ;;
    *)
        sleep 1s
        ;;
    esac
done

if [ ! -f /run.flag ]; then
    # only run onece
    touch /run.flag
    # chang rsyslog, close local syslog and open remote syslog

    # support log via unix sockets; and kernel log
    # sed -i '/$ModLoad\s\+imuxsock/s/^#*/#/g' /etc/rsyslog.conf
    # sed -i '/$ModLoad\s\+imklog/s/^#*/#/g' /etc/rsyslog.conf
    sed -i '/none\s*\-\/var\/log\/syslog/s/^#*/#/g' /etc/rsyslog.d/50-default.conf
    sed -i '/^#cron\.\*/s/^#*//g' /etc/rsyslog.d/50-default.conf
    sed -i '/$ModLoad\s\+imudp/s/^#*//g' /etc/rsyslog.conf
    sed -i '/$UDPServerRun\s\+514/s/^#*//g' /etc/rsyslog.conf
    sed -i '/$ModLoad\s\+imtcp/s/^#*//g' /etc/rsyslog.conf
    sed -i '/$InputTCPServerRun\s\+514/s/^#*//g' /etc/rsyslog.conf
    sed -i '/:ommysql:/c local1.* :ommysql:localhost,Syslog,rsyslog,Password' /etc/rsyslog.d/mysql.conf
    # create necessary user and table
    if [ -z "$REUSE_DB" ]; then
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE Syslog;GRANT ALL ON Syslog.* TO rsyslog@localhost IDENTIFIED BY 'Password';FLUSH PRIVILEGES"
        mysql -u rsyslog -D Syslog -pPassword </usr/share/dbconfig-common/data/rsyslog-mysql/install/mysql
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE loganalyzer;GRANT ALL ON loganalyzer.* TO loganalyzer@localhost IDENTIFIED BY 'Password';FLUSH PRIVILEGES"
        mysql -u loganalyzer -D loganalyzer -pPassword </loganalyzer.sql
    fi
fi

rsyslogd

apachectl restart

sleep infinity
