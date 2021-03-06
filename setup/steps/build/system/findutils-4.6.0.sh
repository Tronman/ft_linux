#!/bin/bash

pkg_source="findutils-4.6.0.tar.gz"

pkg_name="$(basename $(tar -tf $1/$pkg_source | head -n 1 | cut -d'/' -f 1))"

base_dir=$1
log_file=$2"/"$(echo $pkg_name)".log"

status=0

setup(){
	cd $base_dir												|| return
	tar -xf $pkg_source											|| return
	cd $pkg_name												|| return
}

build(){
	# First, suppress a test which on some machines can loop forever
	sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

	
	./configure --prefix=/usr --localstatedir=/var/lib/locate	|| return
	make														|| return
	make install												|| return
	mv -v /usr/bin/find /bin									|| return
	sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb	|| return
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
