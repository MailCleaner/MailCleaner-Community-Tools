#!/bin/bash
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2017 Mentor Reka <reka.mentor@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
#   This script let you import configuration from your MailCleaner Community (2014.10)
#   to the new MailCleaner Community (>= 2017.xx)
#
#   Usage:
#           migration_from_201410.sh

LOGFILE=/var/tmp/migration_tool.log
CONFFILE=/etc/mailcleaner.conf

HOSTID=`grep 'HOSTID' $CONFFILE | cut -d ' ' -f3`
if [ "$HOSTID" = "" ]; then
  HOSTID=1
fi

SRCDIR=`grep 'SRCDIR' $CONFFILE | cut -d ' ' -f3`
if [ "$SRCDIR" = "" ]; then 
  SRCDIR="/opt/mailcleaner"
fi
VARDIR=`grep 'VARDIR' $CONFFILE | cut -d ' ' -f3`
if [ "$VARDIR" = "" ]; then
  VARDIR="/opt/mailcleaner"
fi

HTTPPROXY=`grep -e '^HTTPPROXY' $CONFFILE | cut -d ' ' -f3`
export http_proxy=$HTTPPROXY


function check_parameter {
        if [ "$1" = "" ]; then
                echo "Error: parameter not given.."
                let RETURN=0
        else
                let RETURN=1
        fi
}

#####
# get or ask values
echo "*******************************************"
echo "** Welcome to Mailcleaner migration tool **"
echo "*******************************************"
echo "With this script you can import your configuration from an old MailCleaner Community Edition to the new one."
echo "For that, please give informations of the MailCleaner you want to import"
echo ""

##############################
## MailCleaner informations
##############################
MCIP=$1
if [ "$MCIP" = "" ]; then
let RETURN=0;
while [ $RETURN -lt 1 ]; do
        echo -n "What is your old MailCleaner IP: "
        read MCIP
        check_parameter $MCIP
done
fi

# Import domains and domains prefs
# Import users and emails
# Import administrators
# Import wwlists

echo "Start dumping.."
tbls_to_import="domain domain_pref user user_pref email administrator wwlists"

#while true; do
#    read -p "Do you wish to import white/warn/black lists [y]: " yn
#    case $yn in
#        [Yy]* ) tbls_to_import=$tbls_to_import"wwlists"; break;;
#        [Nn]* ) break;;
#        * ) echo -n "Please answer yes or no.";;
#    esac
#
#done

echo $tbls_to_import &>> $LOGFILE

DATE=`date '+%d-%m-%Y'`;
SAVECONFIG=/tmp/mailcleaner_config_migration_$DATE.sql

CMD="/opt/mysql5/bin/mysqldump -S $VARDIR/run/mysql_master/mysqld.sock -umailcleaner -p\$(grep '^MYMAILCLEANERPWD' /etc/mailcleaner.conf | cut -d ' ' -f3) -ntce mc_config $tbls_to_import > $SAVECONFIG"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$MCIP $CMD
sleep 2s
echo "Start importing.."
scp -C -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$MCIP:$SAVECONFIG $SAVECONFIG &>> $LOGFILE
perl -pi -e 's/INSERT/REPLACE/g' $SAVECONFIG
$SRCDIR/bin/mc_mysql -m mc_config < $SAVECONFIG

echo "********************************"
echo "IMPORTATION SUCCESSFUL !"
echo "Thank you for using Mailcleaner."
echo "********************************"

exit 0
