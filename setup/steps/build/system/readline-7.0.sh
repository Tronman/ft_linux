#!/bin/bash

pkg_source="readline-7.0.tar.gz"

pkg_name="$(basename $(tar -tf $1/$pkg_source | head -n 1 | cut -d'/' -f 1))"

base_dir=$1
log_file=$2"/"$(echo $pkg_name)".log"

status=0

setup(){
	cd $base_dir																	|| return
	tar -xf $pkg_source																|| return
	cd $pkg_name																	|| return
}

build(){
	sed -i '/MV.*old/d' Makefile.in													|| return
	sed -i '/{OLDSUFF}/c:' support/shlib-install									|| return
	
	./configure --prefix=/usr    \
		--disable-static \
		--docdir=/usr/share/doc/readline-7.0										|| return
	
	make SHLIB_LIBS="-L/tools/lib -lncursesw"										|| return
	make SHLIB_LIBS="-L/tools/lib -lncurses" install								|| return

	# Now move the dynamic libraries to a more appropriate
	# location and fix up some symbolic links:
	mv -v /usr/lib/lib{readline,history}.so.* /lib									|| return
	ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so	|| return
	ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so	|| return
	#If desired, install the documentation:
	install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0			|| return
}

teardown(){
	cd $base_dir
	rm -rfv $pkg_name
}

# Internal process

if [ $status -eq 0 ]; then
	setup >> $log_file 2>&1
	status=$?
fi

if [ $status -eq 0 ]; then
	build >> $log_file 2>&1
	status=$?
fi

if [ $status -eq 0 ]; then
	teardown >> $log_file 2>&1
	status=$?
fi

exit $status
