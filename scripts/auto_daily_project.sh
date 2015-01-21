#!/bin/bash
# Build daily snapshot rsyslog package
# ***current working directory must be project dir (e.g. rsyslog)***

# Note: Launchpad does not work with the git hash inside the version
# number, because it checks if the version number as whole is larger
# than what exists. This obviously is not always the case with hashes.
# As such, we rename the version to todays date and time. It looks like
# this works sufficiently good, even when the rsyslog code has the
# "right" (hash-based) version number.

#set -o xtrace

# params
szPlatform=$1
szBranch=$2

# only a single .tar.gz must exist at any time
szSourceFile=`ls *.tar.gz`
szSourceBase=`basename $szSourceFile .tar.gz`
VERSION=`echo $szSourceBase|cut -d- -f2`
LAUNCHPAD_VERSION=`echo $VERSION|cut -d. -f1-3`.`date +%Y%m%d%H%M%S`
szReplaceFile=`echo $szSourceBase | cut -d- -f1`_$LAUNCHPAD_VERSION

if [ "$VERSION" == "`cat LAST_VERSION.$szPlatform`" ]; then
	echo "version $VERSION already built, exiting"
	exit 0
fi

tar xfz $szSourceFile
mv $szSourceFile $szReplaceFile.orig.tar.gz

mv $szSourceBase $LAUNCHPAD_VERSION
cd $LAUNCHPAD_VERSION
cp -r ../$szPlatform/$szBranch/debian .
# create dummy changelog entry
echo "rsyslog ($LAUNCHPAD_VERSION-0adiscon1$szPlatform) $szPlatform; urgency=low" > debian/changelog
echo "" >> debian/changelog
echo "  * daily build" >> debian/changelog
echo "" >> debian/changelog
echo " -- Adiscon package maintainers <adiscon-pkg-maintainers@adiscon.com>  `date -R`" >> debian/changelog 

# Build Source package now!
debuild -S -sa -rfakeroot -k"$PACKAGE_SIGNING_KEY_ID"

# we now need to climb out of the working tree, all distributable
# files are generated in the home directory.
cd ..

# Upload changes to PPA now!
dput -f ppa:adiscon/$szBranch `ls *.changes`

#cleanup
echo $VERSION >LAST_VERSION.$szPlatform
#exit # do this for testing
rm -rf $LAUNCHPAD_VERSION
rm -v $szReplaceFile*.dsc $szReplaceFile*.build $szReplaceFile*.changes $szReplaceFile*.upload *.tar.gz
