#!/bin/sh


genconfig() {
	key_val_list="$1"
	if ! [ -z "$key_val_list" ] ; then
		for i in $key_val_list ; do
			i1=$(echo $i|cut -d '=' -f1)
			i2=$(echo $i|cut -d '=' -f2)
			if grep ^$i1= .config ; then
				echo "mod $i1=$i2"
				sed -i -e "s,^$i1=.*,$i1=$i2," .config
			elif grep "^# $i1 " .config ; then
				echo "akt $i1=$i2"
				sed -i -e "s,^# $i1 .*,$i1=$i2," .config
			else
				echo "add $i1=$i2"
				echo "$i1=$i2" >> .config
			fi
		done
	fi
}


. ./config

pkgname="$1"
DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

for board in $boards ; do
	echo "to see the log just type:"
	echo "tail -f update-build-pkg-$verm-$board-$pkgname.log"
	(
	[ -f update-build-$verm-$board.lock ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
	touch update-build-$verm-$board.lock
	cd $verm/$board/
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	pkgpath=""
	pkgpath=$(find package -maxdepth 1 | grep /$pkgname$)
	echo "$pkgpath"
	[ "$pkgpath" == "" ] && pkgpath=$(find package/feeds -maxdepth 2 | grep /$pkgname$)
	echo "$pkgpath"
	cp ../../ff-control/configs/$verm-$board.config .config
	make oldconfig
	make $pkgpath/clean V=99 && \
	make $pkgpath/compile V=99 && \
	make $pkgpath/install V=99 && \
	make package/index && \
	mkdir -p $wwwdir/$verm/$ver/$board/packages && \
	rsync -lptgoD bin/*/packages/* $wwwdir/$verm/$ver/$board/packages
	cd ../../
	rm update-build-$verm-$board.lock
	) >update-build-pkg-$verm-$board-$pkgname.log 2>&1 &
	#rsync -av "$wwwdir/$verm/$ver/" "$user@$servername:$wwwdir/$verm/$ver"
	#&
done

#for board in $boards ; do
#	if [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"_generic-for-suse-i586.tar.bz2 ] ; then
#		ib_name=OpenWrt-ImageBuilder-"$board"_generic-for-suse-i586
#	elif [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"-for-suse-i586.tar.bz2 ] ; then
#		ib_name=OpenWrt-ImageBuilder-"$board"-for-suse-i586
#	elif [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"_au1500-for-suse-i586.tar.bz2 ] ; then
#		ib_name=OpenWrt-ImageBuilder-"$board"_au1500-for-suse-i586
#	else
#		echo "No IB tar for $board found"
#		exit 0
#	fi
#	rsync -av --delete "$DIR"/"$verm"/"$board"/bin/*/packages/ "$DIR"/"$verm"/meshkit/$ib_name/packages
#	make -C "$DIR"/"$verm"/meshkit/$ib_name package_index
#	sed -i "$DIR"/"$verm"/meshkit/$ib_name/packages/Packages -e '/^MD5Sum.*/d'
#	touch "$DIR"/"$verm"/meshkit/$ib_name/packages/Packages.gz
#done

