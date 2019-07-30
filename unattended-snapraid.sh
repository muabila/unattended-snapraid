#!/bin/bash
#
#  unattended-snapraid.sh
#  © COPYRIGHT 2019 by T.Magerl <dev@muab.org>
#  LICENCE: CC BY-NC-SA 4.0 (see licence-file included)
#

# leave empty for logging to same folder as snapraid.conf file
log_path="/srv/bin/log"

# default-pertence to verify
defaultcheck=1

if pidof -o %PPID -x "$0">/dev/null; then exit 0; fi
snapraid=$(which snapraid)

if [[ $snapraid == "" ]]; then
    echo -e "snapraid not found\nbye"
    exit 1
fi

if [[ -z $1 ]] || [[ ! -f "$1" ]]; then
    echo -e "unattended-snapraid script\n\nusage:\n\n   unattended-snapraid.sh \"/foo/bar/snapraid.conf\" [opt: (integer) percent to verify]\n"
    exit 2
fi

config="$1"

if [[ -z $2 ]]; then
    scheduledcheck=$defaultcheck
fi

DATUM=`date +%y%m%d`

if [[ "$log_path" == "" ]] || [[ ! -d "$log_path" ]]; then
    log_path="$(dirname $config)"
fi

log_file="$log_path/$(basename $config)_$DATUM.log"

echo $( ls -t "$log_path/$(basename $config)"_??????.log | awk 'NR>5' )
echo $( ls -t "$log_path/$(basename $config)"_??????.log | awk 'NR>5' )

exit 0

echo "archive sync for $config"
r=$($snapraid -c "$config" sync)

if [[ ! $r =~ "Nothing to do" ]]; then

    r=$($snapraid -c "$config" -p new scrub)
    echo "archive sync done for $config"

else

    echo "nothing new to sync, scrubbing bad blocks of $config"
    r=$($snapraid -c "$config" -p bad scrub)

    if [[ $r =~ "Nothing to do" ]]; then

        echo "no bad blocks found, scheduled scrubbing of $config"
        r=$($snapraid -c "$config" -p $scheduledcheck scrub) # -o 90
        echo "scheduled scrub done for $config"

    else

        echo "scrubbing bad blocks done in $config"

        fi
    fi

sleep 5

r=$($snapraid -c "$config" touch)

$snapraid -c "$config" status  2>/dev/null \
    | grep -v "|" \
    | grep -v "last scrub" \
    | grep -v "Loading state" \
    | grep -v "Self test" \
    | grep -v "of memory" >> "$log_file"

x=$(cat "$log_file" | grep "snapraid -e fix") && if [[ ! $? == 0 ]]; then
    status="$(cat $log_file) \n \n "
    status="$status \n \n Fixing result: \n $(cat $log_file | grep errors)"

    $snapraid -e -c "$config" fix  2>/dev/null> "$log_file"

    $snapraid -c "$config" smart >> "$log_file"  2>/dev/null
fi

rm $( ls -t "$log_path/$(basename $config)"_??????.log | awk 'NR>7' )

sync

echo "done."

exit 0
