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

mirror_el_repo() {
    local top_url="$1"
    local top_dir=$(url_to_dir "$top_url")
    local kernel_regexp

    local rpm_arch

    case "$arch" in
	amd64 ) rpm_arch="x86_64" ;;
	* ) rpm_arch="$arch" ;;
    esac

    rename_bad_rpm_files "$top_dir"

    # For now, do not include "--no-clobber" in this top level wget.
    # Pull new index.html files every time.  Otherwise, the files do
    # not get updated.  FIXME: Confirm that  timestamps are not
    # supported by the elrepo web server.
    #
    wget --quiet --no-parent -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex='.*/(index.html)?$' \
	 ${top_url}

    save_error

    kernel_regexp="kernel-([a-z]+-)?devel-${above_3_9_regexp}[0-9.]*-.*${rpm_arch}.rpm"

    for dir in ${top_dir}/*/${rpm_arch}/RPMS/ ; do
	echo ''
	extract_subdirs < $dir/index.html |
	    egrep "^${kernel_regexp}\$" |
	    subdirs_to_urls http://${dir#http/}
    done |
	xargs -- wget --quiet --no-parent ${TIMESTAMPING} \
	      --protocol-directories --force-directories

    save_error
}

mirror_download_opensuse_org() {
    local top_url="$1"
    local top_dir=$(url_to_dir "$top_url")

    rename_bad_rpm_files "$top_dir"

    # wget --quiet --protocol-directories --force-directories "${top_url}"
    #
    # extract_subdirs < "$top_dir/index.html" |
    #	egrep '^[1-9][0-9]*\.[0-9]+' |
    #	sed "s|^|${top_url}|;s|\$|/os/x86_64/Packages/|" |
    #	xargs
    wget --quiet --no-parent ${TIMESTAMPING} -e robots=off \
	 --protocol-directories --force-directories --recursive \
	 --accept-regex="/((index.html)||(kernel-.*devel.*\.rpm))$" "$top_url"
    # --level=1
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

# TODO: Maybe add this after filtering for kernel versions 3.10 and later:
# mirror_download_opensuse_org http://dev.suse.org/
mirror_download_opensuse_org http://download.opensuse.org/update/
mirror_download_opensuse_org http://download.opensuse.org/distribution/
save_error

exit $error_code
