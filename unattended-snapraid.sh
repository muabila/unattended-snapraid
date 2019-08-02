#!/bin/bash
#
#  unattended-snapraid.sh
#  © COPYRIGHT 2019 by T.Magerl <dev@muab.org>
#  LICENCE: CC BY-NC-SA 4.0 (see licence-file included)
#

self_config="$(dirname $0)/unattended-snapraid.conf"

if [[ ! -f "$self_config" ]]; then
    log_path=""
    verify_percentage=3
    auto_remove_logs=true
    notice="'$self_config' not found\nedit and rename 'unattended-snapraid.conf-SAMPLE'.\nusing default settings.\n\n"
else
    . "$(dirname $0)"/unattended-snapraid.conf
fi

if pidof -o %PPID -x "$0">/dev/null; then exit 0; fi
snapraid=$(which snapraid)

if [[ $snapraid == "" ]]; then
    echo -e "snapraid not found\nbye"
    exit 1
fi

if [[ -z $1 ]] || [[ ! -f "$1" ]]; then
    echo -e "unattended-snapraid script\n\nusage:\n\n   unattended-snapraid.sh \"/foo/bar/snapraid.conf\" [opt: (integer) percent to verify]\n"
    exit 1
fi

config="$1"

if [[ -z $2 ]]; then
    scheduledcheck=$verify_percentage
fi

DATUM=`date +%y%m%d`

if [[ "$log_path" == "" ]] || [[ ! -d "$log_path" ]]; then
    log_path="$(dirname $config)"
fi

if [[ $auto_remove_logs ]] && [[ $( ls -t "$log_path/$(basename $config)"_??????.log | awk 'NR>7' ) != "" ]]; then
    rm $( ls -t "$log_path/$(basename $config)"_??????.log | awk 'NR>7' )
fi

log_file="$log_path/$(basename $config)_$DATUM.log"
debug_file="$log_path/$(basename $config)_$DATUM.tmp"

echo -e "### snapraid results for '$config', created by unattended-snapraid\n" > "$log_file"

if [[ $notice ]]; then
    echo -e "$notice" >> "$log_file"
fi

action() {
    if [[ $r =~ "Nothing to do" ]]; then
        return 1
    else
        return 0
    fi
}

important() {
    if [[ $r =~ "Nothing to do" ]]; then
        return 1
    elif [[ $r =~ "No rehash is in progress or needed." ]] && \
            [[ $r =~ "No error detected." ]]; then
        return 1
    else
        return 0
    fi
}

log() {
    echo -e "\n$@" >> "$log_file"
    echo -e "\nunattended-snapraid '$config': $@"
}

snap() {
    r=$($snapraid -c "$config" $@)
    exit_code=$?

    if [[ ! $exit_code == 0 ]]; then
        log "\nsnapraid (not unattended-snapraid) failed execution:\n\n$r\n\nplease test snapraid manually"
        exit 2
    fi

    if important; then
        log "$r"
    fi
}

log "syncing changes"
snap sync >>/dev/null

if action; then

    log "scrubbing recent sync"
    snap -p new scrub >>/dev/null

else

    log "no changes found, scrubbing bad blocks"
    snap -p bad scrub >>/dev/null

    if ! action; then
        log "no bad blocks found, scheduled scrubbing ($scheduledcheck%)"
    fi

fi

r=$($snapraid -c "$config" touch)
sync

snap status 2>/dev/null \
    | grep -v "|" \
    | grep -v "last scrub" \
    | grep -v "Loading state" \
    | grep -v "Self test" \
    | grep -v "of memory"

if [[ $(cat "$log_file") =~ "snapraid -e fix" ]]; then

    log "trying to fix found errors"
    snap -e fix

fi

snap smart 2>/dev/null

echo "unattended-snapraid: results saved to '$log_file'"

exit 0
