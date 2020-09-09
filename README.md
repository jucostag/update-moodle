# update-moodle

Script to automate moodle update (the newest version available), keeping your customized plugins.

First, create these environment variables for the script:

- ROOT_DIR - Path where moodle and moodledata directories are
- PROJECT_DIR - Path to moodle application
- CUSTOMIZATIONS_LIST_PATH - Path to the config file that tells the script where are your Moodle customizations

Then, on $CUSTOMIZATIONS_LIST_PATH, create a **.custom** file, and list all your Moodle plugins and customizations. They will be restored after the update. Follow the example below to tell the script which file or directory and where to put it.

Makefile=./
.env=./
auth/<your_auth_plugin>=./auth/
theme/<your_theme>=./theme/