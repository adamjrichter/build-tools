DESTDIR=
scriptsdir=${DESTDIR}/home/pwxmirror/mirror-scripts

all: crontab.txt

crontab.txt: crontab.txt.in
	sed 's|\$${scriptsdir}|${scriptsdir}|g' < crontab.txt.in > crontab.txt

install_mirror_scripts: all
	mkdir -p ${scriptsdir}
	for file in mirror-kernels.*.sh cron-script.sh pwx-mirror-config.sh pwx-mirror-util.sh ; do \
	    sed "s|^scriptsdir=.*$$|scriptsdir=${scriptsdir}|g" \
		< "$$file" > "${scriptsdir}/$$file" ; \
	done
	chmod a+x ${scriptsdir}/*.sh
	apt-get install -y symlinks	# used by cron-script.sh
	install crontab.txt ${scriptsdir}/

install_ftpd_ubuntu:
	apt-get install -y ftpd
	adduser --system ftp
	chown root ~ftp
	sed -e 's|^anonymous$$|# anonymous|' -i /etc/ftpusers
	mkdir -p ~ftp/bin
	cp /bin/ls ~ftp/bin/
	ldd /bin/ls | egrep ' => /' | ( \
	    sed 's/^.* => //;s/(0x[0-9a-f]*) *$$//' ; \
	    for file in \
		/lib/ld-linux.so.2 \
		/lib64/ld-linux-x86-64.so.2 \
	 	/etc/passwd \
		/etc/group \
		/etc/nsswitch.conf \
	        /lib/x86_64-linux-gnu/libnss_files.so.* \
	    ; do \
		if [ -e "$$file" ] ; then \
		    echo "$$file" ; \
		fi ; \
	      done ) | \
	    ( cd / && xargs -- tar --create --dereference ) | \
	    ( cd ~ftp && tar xp )

install_httpd_ubuntu:
	apt-get install --quiet --yes apache2
	-rm -f /var/www/html/mirrors
	-mkdir -p /var/www/html/mirrors
	chown -R pwxmirror /var/www/html/mirrors
	mv /var/www/html/index.html /var/www/html/index.html.orig 2> /dev/null || true

install_mirror_ubuntu: install_mirror_scripts install_httpd_ubuntu install_ftpd_ubuntu
	mkdir -p /var/log/portworx-mirror-server
	adduser --system pwxmirror
	chsh --shell /bin/bash pwxmirror
	chown -R pwxmirror /home/pwxmirror /var/log/portworx-mirror-server
	( . ${scriptsdir}/pwx-mirror-config.sh && \
	  mkdir -p $$mirrordir/misc/centos $$mirrordir/misc/debian $$mirrordir/misc/opensuse $$mirrordir/misc/ubuntu && for subdir in centos debian opensuse ubuntu ; do dir=$$mirrordir/misc/$$subdir ; file=$$dir/README.txt ; if [ ! -e "$$file" ] ; then echo "This directory is for unmirrored kernel header packages and support files related to $$subdir." > $$file ; fi ; done && chown -R pwxmirror $$mirrordir )
#	crontab -u pwxmirror ${scriptsdir}/crontab.txt
#	^^^^^ Do not install the crontab for now, as the current  plan
#	      is for the cron script to be run by Jensen.


install_mirror: install_mirror_scripts install_mirror_ubuntu

install_docker_ubuntu:
	apt-get update
	apt-get install -y apt-transport-https ca-certificates
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get purge lxc-docker
	apt-cache policy docker-engine
	apt-get update
	apt-get install -y linux-image-extra-$$(uname -r) linux-image-extra-virtual docker-engine docker-compose
	service docker start
      # docker run hello-world

install_docker: install_docker_ubuntu

install_pxdev_ubuntu: install_docker_ubuntu
	apt-get install -y git
#	- ( cd ${scriptsdir} && git clone git://github.com/portworx/px-dev.git )
# ^^^ For now, do not create /home/portworx/px-dev, but this may return
# later, for testing in a a px-dev Docker container.

install_pxdev: install_pxdev_ubuntu

install: install_docker install_mirror install_pxdev

clean:
	-rm -f *~ \#* crontab.txt
