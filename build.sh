#!/bin/sh

KERNEL_REPO=Monarudo_GPU_M7
ZIP_NAME=dlxj-4.4-sense5.5-kernel

if ! type "bbootimg" > /dev/null; then
	echo 'bbootimg not found.'
	exit 1
fi

# cd $KERNEL_REPO
# make -j2
# RET=$?
# if [ ! $RET -eq 0 ]; then
# 	echo 'Building kernel failed.'
# 	exit 1
# fi
# 
# cd ..
# echo 'Kernel built successfully.'

if [ ! -d initramfs ]; then
	echo "Error: directory 'initramfs' doesn't exist."
	exit 1
fi
if [ ! -d tmp ]; then
	mkdir tmp
elif [ -f tmp/initrd.img ]; then
	echo 'Removing old initrd.img...'
	rm tmp/initrd.img
fi

if [ ! -d tmp/initramfs ]; then
	mkdir tmp/initramfs
else
	echo 'Cleaning ramdisk working directory...'
	rm -rf tmp/initramfs/*
fi

echo 'Writing new ramdisk to tmp/initrd.img...'
cp -R initramfs tmp/
cd tmp/initramfs
find . -name ".gitignore" -exec rm {} \;
find . -mindepth 1 | cpio -o -H newc | gzip > ../initrd.img

cd ../../
if [ ! -f tmp/initrd.img ]; then
	echo 'Writing new ramdisk failed.'
	exit 1
fi

if [ ! -d tmp/installer ]; then
	mkdir tmp/installer
else
	echo 'Removing old installer...'
	rm -rf tmp/installer/*
fi

echo 'Building boot.img...'
bbootimg --create tmp/installer/boot.img -f bootimg.cfg -k $KERNEL_REPO/arch/arm/boot/zImage -r tmp/initrd.img
if [ ! -f tmp/installer/boot.img ]; then
	echo 'Writing new boot.img failed.'
	exit 1
fi

mkdir -p tmp/installer/META-INF/com/google/android/
echo 'Copying update-binary and scripts...'
cp installer_zip/update-binary tmp/installer/META-INF/com/google/android/
sed -e s/%NAME%/$ZIP_NAME/ < installer_zip/updater-script-template > tmp/installer/META-INF/com/google/android/updater-script

mkdir -p tmp/installer/system/lib/modules/
echo 'Copying modules...'
find $KERNEL_REPO -name *.ko -exec cp {} tmp/installer/system/lib/modules/ \;

echo 'Creating installer zip...'
cd tmp/installer
DATE=$(date +'%Y%m%d')
zip -r ../../$ZIP_NAME-$DATE.zip .
cd ..
RET=$?
if [ ! $RET -eq 0 ]; then
	echo 'Creating zip file failed.'
	exit 1
fi

echo 'Done!'
exit 0
