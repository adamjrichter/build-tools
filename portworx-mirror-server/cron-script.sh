#!/bin/bash
# ^^^^^^^^^ /bin/bash because pwx-mirror-util.sh uses "[[".

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
logdir=/var/log/portworx-mirror-server
main_logfile=${logdir}/cron-script.log

error_code=0

copy_link_tree_remove_index_html()
{
    local from="$1"
    local to="$2"

    set +e
    symlinks -d "${to}"

    # Remove "$from" and/or "$to" if either one is not a directory.  That
    # should never happen, but apparently it somehow can.  Perhaps
    # some install script needs to be fixed.
    rm -f "$from" "$to" 2> /dev/null || true

    cp --symbolic-link --recursive --remove-destination "$from/." "$to"
    save_error

    if [[ -e "$to" ]] ; then
	find "$to" -name index.html -print0 |
	    xargs --null --no-run-if-empty -- rm -f
    fi

    if [[ -e "$to" ]] ; then
	find "$to" -type d | sort -r |
	    xargs --no-run-if-empty rmdir 2> /dev/null || true
    fi

    symlinks -cs "$to"
    save_error
}

run_all_verb_scripts()
{
    local verb="$1"
    local basename logfile

    for script in ${scriptsdir}/${verb}-kernels.*.sh ; do
	basename="${script##*/}"
	logfile="$logdir/${basename}.log"
	if [[ -e "$logfile" ]] ; then
	    mv --force "$logfile" "${logfile}.old"
	fi
        $script > "$logfile" 2>&1
	save_error
    done
}

run_all_mirror_scripts()
{
    run_all_verb_scripts mirror
    copy_link_tree_remove_index_html "${mirrordir}" "${web_mirrordir}"
    # copy_link_tree_remove_index_html "${ftp_top}/build-results" "${web_top}/build-results"
}

run_all_test_scripts()
{
    # For now, disable this, because the new test scripts need to run
    # as root to run lxc commands.  This should be fixable as LXC does
    # have some support for running containers by a non-superuser
    # (via lxd?).
    #
    # run_all_verb_scripts test
    true
}

mkdir -p "$logdir"

if [[ -e "$main_logfile" ]] ; then
    mv --force "$main_logfile" "${main_logfile}.old}"
fi
( run_all_mirror_scripts ; run_all_test_scripts ) > "$main_logfile" 2>&1 < /dev/null
save_error

exit $error_code
