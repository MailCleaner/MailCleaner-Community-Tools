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
#   Fix DB and SpamHandler for clustering MailCleaner Community Edition 2014.10 with 2017.xx
#   Usage:
#           mix_cluster.sh

VARDIR=`grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3`
if [ "VARDIR" = "" ]; then
  VARDIR=/var/mailcleaner
fi
SRCDIR=`grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3`
if [ "SRCDIR" = "" ]; then
  SRCDIR=/var/mailcleaner
fi
VERSION=`cat $SRCDIR/etc/mailcleaner/version.def`
if [ "VERSION" != "2014.10" ]; then
	echo "This script is not useful for other version than 2014.10"
	exit 0
fi

MYMAILCLEANERPWD=`grep 'MYMAILCLEANERPWD' /etc/mailcleaner.conf | cut -d ' ' -f3`

read -r -d '' MC_SPOOL << EOF
USE mc_spool;
DROP TABLE spam;
ALTER TABLE mc_spool.spam_a
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_b
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_c
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_d
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_e
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_f
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_g
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_h
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_i
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_j
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_k
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_l
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_m
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_n
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_o
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_p
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_q
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_r
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_s
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_t
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_u
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_v
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_w
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_x
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_y
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_z
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_num
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
ALTER TABLE mc_spool.spam_misc
ADD COLUMN is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0' AFTER M_globalscore;
CREATE TABLE spam (
  date_in date NOT NULL,
  time_in time NOT NULL,
  to_domain varchar(100) NOT NULL,
  to_user varchar(100) NOT NULL,
  sender varchar(120) NOT NULL,
  exim_id varchar(16) NOT NULL,
  M_date varchar(50) DEFAULT NULL,
  M_subject varchar(250) DEFAULT NULL,
  forced enum('1','0') NOT NULL DEFAULT '0',
  in_master enum('1','0') NOT NULL DEFAULT '0',
  store_slave int(11) NOT NULL,
  M_rbls varchar(250) DEFAULT NULL,
  M_prefilter varchar(250) DEFAULT NULL,
  M_score decimal(7,3) DEFAULT NULL,
  M_globalscore int(11) DEFAULT NULL,
  is_newsletter ENUM('1', '0') NOT NULL DEFAULT '0',
  KEY exim_id_idx (exim_id),
  KEY to_user_idx (to_user,to_domain),
  KEY date_in_idx (date_in)
);
ALTER TABLE spam ENGINE=merge UNION=(spam_a,spam_b,spam_c,spam_d,spam_e,spam_f,spam_g,spam_h,spam_i,spam_j,spam_k,spam_l,spam_m,spam_n,spam_o,spam_p,spam_q,spam_r,spam_s,spam_t,spam_u,spam_v,spam_w,spam_x,spam_y,spam_z,spam_num,spam_misc) INSERT_METHOD=last;
EOF

# Fix mc_spool DB (slave and master)
echo "$MC_SPOOL" | $SRCDIR/bin/mc_mysql -s
echo "$MC_SPOOL" | $SRCDIR/bin/mc_mysql -m

$SRCDIR/etc/init.d/mysql_slave restart
$SRCDIR/etc/init.d/mysql_master restart

# Fix SpamHandler
sed -i 's/$this->{sc_global},  $$inmasterh.*/$this->{sc_global},  $$inmasterh, 0/g' $SRCDIR/lib/SpamHandler/Message.pm

$SRCDIR/etc/init.d/spamhandler restart


