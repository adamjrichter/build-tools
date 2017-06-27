#!/bin/bash
# ^^ requires bash because save_error() calls bash_stack_trace,
# which uses bash-specific command "caller".

#arch=i386
arch=x86_64

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
cd ${mirrordir} || exit $?
mkdir -p ${mirrordir}

# TIMESTAMPING=--timestamping
TIMESTAMPING='--no-clobber --no-use-server-timestamps'

error_code=0

mirror_download_opensuse_org() {
    local top_url="$1"
    local top_dir=$(url_to_dir "$top_url")
    local QUIET="--quiet"
    # local QUIET="--debug"

    rename_bad_rpm_files "$top_dir"

    # wget --quiet --protocol-directories --force-directories "${top_url}"
    #
    # extract_subdirs < "$top_dir/index.html" |
    #	egrep '^[1-9][0-9]*\.[0-9]+' |
    #	sed "s|^|${top_url}|;s|\$|/os/x86_64/Packages/|" |
    #	xargs
    #
    # wget will not load the .rpm files from
    # http://download.opensuse.org/distribution/openSUSE-current/repo/oss/suse/x86_64 unless "--level" is explicitly set to a big number because "the default
    # maximum depth is 5" according to the wget manual page.

    # First update all index.html files, then look for new .rpm files without
    # rereading the .rpm files.

    wget --level=8 ${QUIET} --no-parent -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex="/((index.html)|)$" "$top_url"

    # The ${TIMESTAMPING} argument should prevent existing .rpm files
    # from being reread, because ${TIMESTAMPING} includes --no-clobber.

    wget --level=8 ${QUIET} --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex="/((index.html)||(kernel-.*devel.*\.rpm))$" "$top_url"

    #                                         ^^^
    # Notice that the "--accept-regexp=..." argument is written to allow
    # more characters between the "kernel-" and "devel", to accomodate
    # packages name kenrel-ml-devel... and kernel-lt-devel... for
    # "main line" and "long term" kernels.
    #
    # FIXME.  The following regular expresion might filter out kernels before
    # 3.10.  It is modified from one that was not working, but maybe this
    # version might work.
    #
    # --accept-regex="/(index.html)|(kernel-(.*-)?headers-${above_3_9_regexp}(.*-.*-.*)?\..*\.rpm)"

    save_error
}

mirror_download_opensuse_org http://download.opensuse.org/distribution/
save_error

mirror_download_opensuse_org http://download.opensuse.org/update/
save_error

exit $error_code
