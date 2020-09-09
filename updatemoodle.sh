#!/bin/bash

# Author: Juliana Gonçalves da Costa Soares <juliana.goncosta@gmail.com>
# Author URI: https://github.com/jucostag

# KEEPING SOME DATA TO USE LATER
########################################################################

DATE=$(which date)
UPDATE_TIME=$($DATE +%m%d%Y%H%M%S)

OLD_MOODLE_DIR=$ROOT_DIR/moodle_old_$UPDATE_TIME
NEW_MOODLE_DIR=$ROOT_DIR/moodle_new_$UPDATE_TIME

# SOME FUNCTIONS TO ORGANIZE
#######################################################################
FIND_HIDDEN=$(find $PROJECT_DIR -maxdepth 1 -type f -name ".*")
FIND_HIDDEN_NEW_MOODLE=$(find $NEW_MOODLE_DIR -maxdepth 1 -type f -name ".*")

copyHiddenFromProject() {
	#including .git dir 
	cp -r $PROJECT_DIR/.git $OLD_MOODLE_DIR/

	for file in $FIND_HIDDEN; do
		cp -r $PROJECT_DIR/$file $OLD_MOODLE_DIR/
	done
}

removeHiddenFromProject() {
	for file in $FIND_HIDDEN; do
		rm -rf $PROJECT_DIR/$file
	done
}

copyHiddenFromNewMoodle() {
	for file in $FIND_HIDDEN_NEW_MOODLE; do
		cp -r $NEW_MOODLE_DIR/$file $PROJECT_DIR
	done
}

restoreCustom() {
	while read custom_item; do 
		echo "Copying ${custom_item}"
		
		custom_item=${custom_item/$'\r'/}
		restore_item=$(echo $custom_item | cut -d '=' -f 1)
		restore_destination=$(echo $custom_item | cut -d '=' -f 2)

		cp -R "${OLD_MOODLE_DIR}/${restore_item}" "${PROJECT_DIR}/${restore_destination}"
		wait

	done < $CUSTOMIZATIONS_LIST_PATH/.custom
	wait
}

# INITIALIZING THE UPDATE BY PREPARING THE CURRENT PROJECT
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Initializing Moodle Update..."

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Saving a backup of your current Moodle version in $OLD_MOODLE_DIR..."

mkdir $OLD_MOODLE_DIR
cp -r $PROJECT_DIR/* $OLD_MOODLE_DIR
copyHiddenFromProject

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Cleaning $PROJECT_DIR..."

rm -rf $PROJECT_DIR/*
removeHiddenFromProject

# CLONING NEW MOODLE VERSION
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Creating $NEW_MOODLE_DIR and downloading the new version from Moodle Repository..."

cd $ROOT_DIR
mkdir $NEW_MOODLE_DIR

git clone https://github.com/moodle/moodle.git $NEW_MOODLE_DIR

cd $NEW_MOODLE_DIR

git fetch --tags

MOST_RECENT_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))

git checkout $MOST_RECENT_TAG
rm -r .git/

# COPYING NEW VERSION
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Copying new Moodle version for your project..."

cd $PROJECT_DIR

cp -R $NEW_MOODLE_DIR/* $PROJECT_DIR
copyHiddenFromNewMoodle

# RESTORING CUSTOMIZATIONS FOR THE UPDATED VERSION
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Restoring customizations from backup..."

restoreCustom

# REMOVING BACKUP AND CLONE DIRECTORIES
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Removing $OLD_MOODLE_DIR and $NEW_MOODLE_DIR..."

rm -r $OLD_MOODLE_DIR
rm -r $NEW_MOODLE_DIR

# PURGING MOODLE CACHE
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Purging Moodle cache..."

php $PROJECT_DIR/admin/cli/purge_caches.php

# RUNNING PHPUNIT TESTS
########################################################################

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Running PHPUnit tests..."

php $PROJECT_DIR/admin/tool/phpunit/cli/init.php

echo "[ $($DATE +%m/%d/%Y\ %H:%M:%S) ] - [ INFO ] - Success! Moodle is up-to-date! You can now validate the new core version."
