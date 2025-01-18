#!/bin/bash

# SFTP server details
SFTP_HOST=""
SFTP_PORT="22"  # Default is 22, change if needed
SFTP_USER=""
SFTP_PASSWORD=""
REMOTE_SCRIPT_DIR=""
REMOTE_DIR=""
LOCAL_DIR=""
REMOTE_SCRIPT=""

# Check for command-line arguments for start and end dates
if [ -n "$1" ] && [ -n "$2" ]; then
    START_DATE=$1
    END_DATE=$2
else
    # Default to Date-2 for START_DATE and Date-1 for END_DATE
    START_DATE=$(date -d "2 days ago" +"%Y-%m-%d")
    END_DATE=$(date -d "yesterday" +"%Y-%m-%d")
fi

# Construct the filename based on the END_DATE
REMOTE_FILE="ticket_${END_DATE}.csv"
echo "Remote file to download: $REMOTE_FILE"

# SSH login to run Python script for API data pull
expect <<EOF
set timeout -1
spawn /usr/bin/ssh ${SFTP_USER}@${SFTP_HOST}
expect {
    timeout { send_user "\nFailed to get password prompt\n"; exit 1 }
    eof { send_user "\nSSH failed for ${SFTP_HOST}\n"; exit 2 }
    *assword:
}
send "${SFTP_PASSWORD}\r"
expect {
    "*$ " { send_user "\nLogged in successfully\n" }
    denied { send_user "\nLogin Unsuccessful with given User/Password\n"; exit 3 }
}

send "cd ${REMOTE_SCRIPT_DIR} \r"
expect "*$ "
send "python3 ${REMOTE_SCRIPT} ${START_DATE} ${END_DATE} \r"
expect "*$ "
send "exit \r"
interact
EOF

# Check if SSH command executed successfully
ERR_CD=`echo $?`
if [ ${ERR_CD} -eq 0 ]; then
    echo "File downloaded successfully from API"
else
    echo "File download failed"
    exit 6
fi

# Purge old dump files
# if local_dir doesn't exist, quit script rather than executing `rm` command
cd ${LOCAL_DIR} || exit
rm -f ticket_*.csv

# Download file with SFTP protocol
lftp -p $SFTP_PORT -u $SFTP_USER,$SFTP_PASSWORD sftp://$SFTP_HOST <<END_SCRIPT
cd ${REMOTE_DIR}
lcd ${LOCAL_DIR}
get ${REMOTE_FILE}
bye
END_SCRIPT

# Verify the file download
if [ -f "$LOCAL_DIR/$REMOTE_FILE" ]; then
    echo "Download complete. File saved to $LOCAL_DIR/$REMOTE_FILE"
else
    echo "File not found: $REMOTE_FILE"
fi

# Generate file list for ticket dump
find ${LOCAL_DIR} -name ${REMOTE_FILE} > ${LOCAL_DIR}/file_list_ticket.txt
