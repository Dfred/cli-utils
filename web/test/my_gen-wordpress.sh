#!/bin/bash

#
# This script configures wippy (cf: https://bitbucket.org/xfred/wippy-spread-advanced/src )
# NOTE: Arrays cannot be directly exported in bash
#

sitename=test

set -a
url=http://$sitename/                     #XXX: add an alias in your hosts file
email="www.wippy@manymakers.net"           #XXX: e2gf developper contact email
title="test wippy installer"
description="generating a fresh site on the fly"
path_overlay="/vagrant"
url_overlaygit=""
path_install="/var/www/wordpress"
admin_login="wippy"
pwd_wordpress="password"
#pwd_mysql="password"

deps_plugin=""
wp_debug="true"
create_pages="Accueil"

## see wp theme mod get --all
post_install="bot_info \"Add more commands (using \\$wp for instance) in \$post_install, and don't forget escaping.\";
"


#test -n "$1" && $1 $sitename ||
./wippy.sh $1 $sitename
