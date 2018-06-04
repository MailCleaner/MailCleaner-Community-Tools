#!/bin/bash
#set -x

# Checks the MailCleaner overall status using SNMP values.
# 
# NB: don't forget to allow the monitoring poller IP in the MailCleaner configuration
#     ( Configuration => Services => SNMP monitoring )
# 
# 
# by fabricat
# 

: <<'SNMP-DOCUMENTATION'
Source: http://www.mailcleaner.org/doku.php/documentation:snmp_monitoring


Here are the few more traps provided by MailCleaner:

  extOutput.1 (1.3.6.1.4.1.2021.8.1.101.1): number of filtered messages (integer)

  extOutput.2 (1.3.6.1.4.1.2021.8.1.101.2): number of spams detected (integer)

  extOutput.3 (1.3.6.1.4.1.2021.8.1.101.3): number of bytes filtered (integer)

  extOutput.4 (1.3.6.1.4.1.2021.8.1.101.4): number of viruses detected (integer)

  extOutput.5 (1.3.6.1.4.1.2021.8.1.101.5): processes status (boolean list e.g: |1|1|1|1|1|1|1|1).
    Definition and order of processes (0 = down, 1= running):
        incoming MTA (critical)
        queuing MTA (critical)
        outgoing MTA (critical)
        Web GUI (not critical)
        antispam/antivirus process/filtering engine (critical)
        master database (not critical)
        slave database (critical)
        firewall (not critical)

  extOutput.6 (1.3.6.1.4.1.2021.8.1.101.6): spools status, number of messages in queues (integer list, e.g.:|190|4|26)
    Definition and order of spools:
        incoming : incoming MTA. Messages can be stored here on massive attacks, or when the MailCleaner is used as an outgoing relay for your network.
        filtering: main engine spool. Messages are stored here when processed by the engine. Less than 300 messages is normal because messages are NOT deleted here until process if completly finished). More messages can be an indication that your system is getting a little bit busy at the time.
        outgoing: outgoing MTA. MEssages are stored here when they cannot be delivered immediatly (temporary failure of destination host)

  extOutput.7 (1.3.6.1.4.1.2021.8.1.101.7): system load (float list, e.g. |5.29|3.79|3.55)
    Definition and order of loads:
         5 minutes:  5 last minutes average
        10 minutes: 10 last minutes average
        15 minutes: 15 last minutes average dernieres minutes

  extOutput.8 (1.3.6.1.4.1.2021.8.1.101.8): disk partitions usage (list of string, e.g. |/|32%|/var|35%)

  extOutput.9 (1.3.6.1.4.1.2021.8.1.101.9): system memory usage (integer list, e.g. |2068628|177144|1951888|1936572)
    Definition and order of usages:
        total physical memory
        free physical memory
        total swap memory
        free swap memory

  extOutput.10 (1.3.6.1.4.1.2021.8.1.101.10): all daily counts (integer list)
    Definition and order of counts:
    $total_bytes|$total_msg|$total_spam|$percentspam|$total_virus|$percentvirus|$total_content|$percentcontent|$total_clean|$percentclean
        number of bytes filtered
        number of messages filtered
        number of spams detected
        spam percentage
        number of viruses detected
        viruses percentage
        number of dangerous content detected
        dangerous content percentage
        number of clean messages
        clean messages percentages

SNMP-DOCUMENTATION

# Default values
COMMUNITY="mailcleaner"
MC_HOST="127.0.0.1"
VERBOSE="0"

SNMPWALK="/usr/bin/snmpwalk"


# Default thresholds
MSG_SPAM_CRIT=70
MSG_SPAM_WARN=50

MSG_VIRUS_CRIT=30
MSG_VIRUS_WARN=15

MSG_QUEUE_CRIT=100
MSG_QUEUE_WARN=50

LOAD_CRIT=10
LOAD_WARN=5

MEM_CRIT=90
MEM_WARN=75

SWAP_CRIT=80
SWAP_WARN=50

DISK_CRIT=90
DISK_WARN=80




USAGE=" Usage: $0 [options...]

 Options:
    -H <string>    MailCleaner host or IP              (default: ${MC_HOST})
    -C <string>    SNMP read community                 (default: ${COMMUNITY})
    -v             Verbose output                      
    -V             Very verbose output                 
    -h             Print this help and exit            
    -w <int>       Spam warning percentage             (default: ${MSG_SPAM_WARN})
    -c <int>       Spam error percentage               (default: ${MSG_SPAM_CRIT})
    -r <int>       Virus warning percentage            (default: ${MSG_VIRUS_WARN})
    -R <int>       Virus error percentage              (default: ${MSG_VIRUS_CRIT})
    -q <int>       Mail queues warning level           (default: ${MSG_QUEUE_WARN})
    -Q <int>       Mail queues error level             (default: ${MSG_QUEUE_CRIT})
    -l <int>       System load warning level           (default: ${LOAD_WARN})
    -L <int>       System load error level             (default: ${LOAD_CRIT})
    -m <int>       Memory load warning percentage      (default: ${MEM_WARN})
    -M <int>       Memory load error percentage        (default: ${MEM_CRIT})
    -s <int>       Swap load warning percentage        (default: ${SWAP_WARN})
    -S <int>       Swap load error percentage          (default: ${SWAP_CRIT})
    -d <int>       Partitions usage warning percentage (default: ${DISK_WARN})
    -D <int>       Partitions usage error percentage   (default: ${DISK_CRIT})
"
# Getting parameters:
while getopts "H:C:vVhw:c:r:R:q:Q:l:L:m:M:s:S:d:D:" OPT
do
	case $OPT in
		"H") MC_HOST=$OPTARG;;
		"C") COMMUNITY=$OPTARG;;
		"v") if [ "$VERBOSE" -lt "1" ]; then VERBOSE="1"; fi;;
		"V") VERBOSE="2";;
		"h") echo "$USAGE" && exit 3;;
		"w") MSG_SPAM_WARN=$OPTARG;;
		"c") MSG_SPAM_CRIT=$OPTARG;;
		"r") MSG_VIRUS_WARN=$OPTARG;;
		"R") MSG_VIRUS_CRIT=$OPTARG;;
		"q") MSG_QUEUE_WARN=$OPTARG;;
		"Q") MSG_QUEUE_CRIT=$OPTARG;;
		"l") LOAD_WARN=$OPTARG;;
		"L") LOAD_CRIT=$OPTARG;;
		"m") MEM_WARN=$OPTARG;;
		"M") MEM_CRIT=$OPTARG;;
		"s") SWAP_WARN=$OPTARG;;
		"S") SWAP_CRIT=$OPTARG;;
		"d") DISK_WARN=$OPTARG;;
		"D") DISK_CRIT=$OPTARG;;
	esac
done


# Other variables
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

ISSUECRIT=""
ISSUEWARN=""
ISSUEOK=""
STATS=""

SEPARATOR=" - "





# Get data from SNMP queries
DAILY_COUNTS=$(${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.10 2>&1)
if [ $? -ne 0 ]
then
	echo "CRITICAL: $DAILY_COUNTS"
	exit $STATE_CRITICAL
fi

MSG_TOTAL=$(   ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.1)
MSG_SPAM=$(    ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.2)
MSG_BYTES=$(   ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.3)
MSG_VIRUS=$(   ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.4)

PROCS_STATUS=$(${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.5)
SPOOL_STATUS=$(${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.6)

LOAD_STATUS=$( ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.7)
PART_STATUS=$( ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.8)
MEM_STATUS=$(  ${SNMPWALK} -v2c -c ${COMMUNITY} -O qv ${MC_HOST} 1.3.6.1.4.1.2021.8.1.101.9)



# Process some stats
STATS="${STATS} msg_tot=${MSG_TOTAL} msg_spam=${MSG_SPAM} msg_virus=${MSG_VIRUS}"

### Process data

# Queue status
incoming=$(echo ${SPOOL_STATUS} | cut -d'|' -f 2)
filtered=$(echo ${SPOOL_STATUS} | cut -d'|' -f 3)
outgoing=$(echo ${SPOOL_STATUS} | cut -d'|' -f 4)
STATS="${STATS} queue_in=${incoming} queue_filter=${filtered} queue_out=${outgoing}"

MSG="Queue count: $incoming incoming, $filtered filtered, $outgoing outgoing"
if [ $incoming -ge $MSG_QUEUE_CRIT -o $filtered -ge $MSG_QUEUE_CRIT -o $outgoing -ge $MSG_QUEUE_CRIT ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ $incoming -ge $MSG_QUEUE_WARN -o $filtered -ge $MSG_QUEUE_WARN -o $outgoing -ge $MSG_QUEUE_WARN ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi


# Procs status
mta_in=$(     echo ${PROCS_STATUS} | cut -d'|' -f 2)
mta_queue=$(  echo ${PROCS_STATUS} | cut -d'|' -f 3)
mta_out=$(    echo ${PROCS_STATUS} | cut -d'|' -f 4)
web_gui=$(    echo ${PROCS_STATUS} | cut -d'|' -f 5)
filt_engine=$(echo ${PROCS_STATUS} | cut -d'|' -f 6)
master_db=$(  echo ${PROCS_STATUS} | cut -d'|' -f 7)
slave_db=$(   echo ${PROCS_STATUS} | cut -d'|' -f 8)
firewall=$(   echo ${PROCS_STATUS} | cut -d'|' -f 9)

if [ "$mta_in" == "1" ]
then
	ISSUEOK="${ISSUEOK}Incoming MTA: running\n"
else
	ISSUECRIT="${ISSUECRIT}Incoming MTA down${SEPARATOR}"
fi

if [ "$mta_queue" == "1" ]
then
	ISSUEOK="${ISSUEOK}Queuing MTA: running\n"
else
	ISSUECRIT="${ISSUECRIT}Queuing MTA down${SEPARATOR}"
fi

if [ "$mta_out" == "1" ]
then
	ISSUEOK="${ISSUEOK}Outgoing MTA: running\n"
else
	ISSUECRIT="${ISSUECRIT}Outgoing MTA down${SEPARATOR}"
fi

if [ "$web_gui" == "1" ]
then
	ISSUEOK="${ISSUEOK}Web GUI: running\n"
else
	ISSUEWARN="${ISSUEWARN}Web GUI down${SEPARATOR}"
fi

if [ "$filt_engine" == "1" ]
then
	ISSUEOK="${ISSUEOK}Antispam/antivirus process/filtering engine: running\n"
else
	ISSUECRIT="${ISSUECRIT}Antispam/antivirus process/filtering engine down${SEPARATOR}"
fi

if [ "$master_db" == "1" ]
then
	ISSUEOK="${ISSUEOK}Master DB: running\n"
else
	ISSUEWARN="${ISSUEWARN}Master DB down${SEPARATOR}"
fi

if [ "$slave_db" == "1" ]
then
	ISSUEOK="${ISSUEOK}Slave DB: running\n"
else
	ISSUECRIT="${ISSUECRIT}Slave DB down${SEPARATOR}"
fi

if [ "$firewall" == "1" ]
then
	ISSUEOK="${ISSUEOK}Firewall: running\n"
else
	ISSUEWARN="${ISSUEWARN}Firewall down${SEPARATOR}"
fi


# Load status
load05=$(echo ${LOAD_STATUS} | cut -d'|' -f 2)
load10=$(echo ${LOAD_STATUS} | cut -d'|' -f 3)
load15=$(echo ${LOAD_STATUS} | cut -d'|' -f 4)
STATS="${STATS} load5=${load05} load10=${load10} load15=${load15}"

MSG="System load: $load05/$load10/$load15"
load05=${load05/.*}
load10=${load10/.*}
load15=${load15/.*}
if [ "$load05" -ge "$LOAD_CRIT" -o "$load10" -ge "$LOAD_CRIT" -o "$load15" -ge "$LOAD_CRIT" ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ "$load05" -ge "$LOAD_WARN" -o "$load10" -ge "$LOAD_WARN" -o "$load15" -ge "$LOAD_WARN" ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi


# Memory status
ram_tot=$(  echo ${MEM_STATUS} | cut -d'|' -f 2)
ram_free=$( echo ${MEM_STATUS} | cut -d'|' -f 3)
swap_tot=$( echo ${MEM_STATUS} | cut -d'|' -f 4)
swap_free=$(echo ${MEM_STATUS} | cut -d'|' -f 5)

ram_perc=$(expr  100 - \( $ram_free  \* 100 / $ram_tot  \) )
swap_perc=$(expr 100 - \( $swap_free \* 100 / $swap_tot \) )
STATS="${STATS} ram=${ram_perc}% swap=${swap_perc}%"

MSG="Memory load: ${ram_perc}%"
if [ "$ram_perc" -ge "$MEM_CRIT" ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ "$ram_perc" -ge "$MEM_WARN" ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi

MSG="Swap load: ${swap_perc}%"
if [ "$swap_perc" -ge "$SWAP_CRIT" ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ "$swap_perc" -ge "$SWAP_WARN" ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi


# Disk partitions status
i="2"
part_name=$(echo ${PART_STATUS} | cut -d'|' -f $i)
while [ "$part_name" != "" ]
do
	i=$(( $i + 1 ))
	part_perc=$(echo ${PART_STATUS} | cut -d'|' -f $i)
	STATS="${STATS} ${part_name}=${part_perc}"

	MSG="Disk ${part_name}: ${part_perc}"
	if [ "${part_perc%\%}" -ge "$DISK_CRIT" ]
	then
		ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
	elif [ "${part_perc%\%}" -ge "$DISK_WARN" ]
	then
		ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
	else
		ISSUEOK="${ISSUEOK}${MSG}\n"
	fi

	i=$(( $i + 1 ))
	part_name=$(echo ${PART_STATUS} | cut -d'|' -f $i)
done


# Spam / malicious percentage status
spam_perc=$( echo ${DAILY_COUNTS} | cut -d'|' -f 4)
virus_perc=$(echo ${DAILY_COUNTS} | cut -d'|' -f 6)
clean_perc=$(echo ${DAILY_COUNTS} | cut -d'|' -f 10)
STATS="${STATS} spam=${spam_perc}% virus=${virus_perc}% clean=${clean_perc}%"

MSG="Spam load: ${spam_perc}"
if [ "${spam_perc/.*}" -ge "$MSG_SPAM_CRIT" ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ "${spam_perc/.*}" -ge "$MSG_SPAM_WARN" ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi

MSG="Virus load: ${virus_perc}"
if [ "${virus_perc/.*}" -ge "$MSG_VIRUS_CRIT" ]
then
	ISSUECRIT="${ISSUECRIT}${MSG}${SEPARATOR}"
elif [ "${virus_perc/.*}" -ge "$MSG_VIRUS_WARN" ]
then
	ISSUEWARN="${ISSUEWARN}${MSG}${SEPARATOR}"
else
	ISSUEOK="${ISSUEOK}${MSG}\n"
fi




# Prepare output values
RETSTATE=$STATE_OK
if [ -n "$ISSUECRIT" ]
then
	echo -n "CRITICAL: $ISSUECRIT"
	RETSTATE=$STATE_CRITICAL
fi
if [ -n "$ISSUEWARN" ]
then
	echo -n "WARNING: $ISSUEWARN"
	if [ "$RETSTATE" -lt "$STATE_WARNING" ]
	then
		RETSTATE=$STATE_WARNING
	fi
fi
if [ $RETSTATE -eq $STATE_OK ]
then
	echo -n "OK"
fi

echo " |$STATS"

if [ -n "$ISSUEOK" -a "${VERBOSE}" -ge "1" ]
then
	echo -e "\n$ISSUEOK"
fi

if [ "${VERBOSE}" -ge "2" ]
then
	echo "Raw SNMP values:
 1. number of filtered messages = ${MSG_TOTAL}
 2. number of spams detected = ${MSG_SPAM}
 3. number of bytes filtered = ${MSG_BYTES}
 4. number of viruses detected = ${MSG_VIRUS}
 5. processes status = ${PROCS_STATUS//\|/#}
 6. spools status (messages in incoming#filtering#outgoing queues) = ${SPOOL_STATUS//\|/#}
 7. system load (last 5#10#15minutes) = ${LOAD_STATUS//\|/#}
 8. disk partitions usage = ${PART_STATUS//\|/#}
 9. system memory usage in kB (tot_ram#free_ram#tot_swap#free_swap) = ${MEM_STATUS//\|/#}
10. all daily counts (bytes#msg#spam#%spam#virus#%virus#content#%content#clean#%clean) = ${DAILY_COUNTS//\|/#}"

fi

exit $RETSTATE
