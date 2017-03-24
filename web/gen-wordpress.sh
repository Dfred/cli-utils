#!/bin/bash
#
## Wippy (｡◕‿◕｡)
## AUTOMATIZE/EASE YOUR WordPress INSTALLATION. (Funny pet project).
##
## *** RECOMMENDED FOR LAZY PEOPLE LIKE US ***
##
## AUTHOR: fd@manymakers.fr (2016)
## PART OF: cli-utils FROM git@github.com:Dfred/cli-utils.git
## ORIGIN: @maximebj (maxime@smoothie-creative.com) GET IT FROM
##  https://bitbucket.org/xfred/wippy-spread-advanced/
##
## ##   REGULAR COMMENTS
## #    CODE TOGGLE
## #XXX: COMMENTS TO PROGRAMMERS (LESSER KNOWN/TRICKY STUFF)
## #TDL: TO DO LATER
## #SEC: SECURITY CONCERN

#TDL: DETECT service, systemctl OR (httpd|mysqld)
#TDL: ADD SUPPORT FOR MULTISITE
#TDL: internationalise

source ../base/prompted.sh
source ../base/sys.sh

if [ "${BASH_VERSINFO}" -lt 4 ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "Sorry: spawning Wippy requires bash version 4.0 or later." >&2
  exit $EXIT_UNUSABLE_SYS
fi

readonly HELP=" $0 [--help] [--devel|--test] sitename

 --help:        This help.
 --devel:       Automate the script for developing (you'll have a ready-to-dev
                configuration)
 --test:        Automate the script for testing (you'll have a close-to-prod
                configuration).
 If devel and test options (or variables) are not set, you'll be asked for
 decisions, letting you fix potential situations before answering.

   sitename:    Name of created folder and database. Will lookup for and load
                \$sitename-wippy.conf (a bash script really) that should contain
                bash-style definitions used by wippy.
 Exit status:
 1 : commandline error
 2 : environment / fs error

 Also, see the $0 file itself for additional info on configuration.
"
## PASSWORDS AND OTHER VARIABLES CAN BE SET ON THE COMMAND LINE AS WELL.
## e.g: title="My Blog" email=usr@domain.tld ./wippy.sh mySite
##
## MacOS: GET Git AT http://git-scm.com/downloads
## MacOS: GET subl AT https://www.sublimetext.com/docs/3/osx_command_line.html

## ===========================================================
## = NON DEFAULT REQUIRED VARIABLES TO BE DEFINED EXTERNALLY =
## ===========================================================

## REQUIRED: EMAIL OF WordPress ADMIN.
#email=""

## REQUIRED: TITLE OF FOR THIS WordPress SITE.
#title=""

## ===========================================================
## = NON DEFAULT OPTIONAL VARIABLES TO BE DEFINED EXTERNALLY =
## ===========================================================

## WEBSITE DESCRIPTION.
#description=""                           ## NOT ALWAYS DISPLAYED BY THEMES.

## PASSWORD FOR MySQL root. AVOID WHITESPACE CHARACTERS.
#pwd_mysql=""                             ## GENERATED IF EMPTY.

## PASSWORD FOR WordPress ADMIN. AVOID WHITESPACE CHARACTERS.
#pwd_wordpress=""                         ## GENERATED IF EMPTY.

## CANONICAL PATH TO INSTALL YOUR WordPress.
#path_install=""                          ## DEFINED IN NEXT SECTION IF EMPTY.

## CANONICAL PATH TO DIRECTORY TO LAY OVER WordPress FILES.
## WILL LINK TO $path_overlay/plugins/* AND
##              $path_overlay/themes/*  AND ACTIVATE EACH.
#path_overlay=""

## GIT URL FOR git clone $url_overlaygit.
## EXPECTED DIRECTORY STRUCTURE IS SIMILAR TO $path_overlay.
#url_overlaygit=""                        ## APPEND OPTIONS IF NEEDED.

## TARGETS TO CREATE. CREATE PLUGIN AND/OR (CHILD)THEME NAMED AFTER $sitename.
## INCLUDES CREATION OF DEV-READY FILES:  plugins/$sitename/$sitename.php
##                                        themes/$sitename/$sitename.php.
## KEYWORDS: plugin theme childtheme. CANNOT CREATE BOTH THEME AND CHILD THEME.
#create_content=""                        ## EMPTY, ANY OR TWO KEYWORD(S).

## NAME OF PAGES TO CREATE. SINGLE QUOTES REQUIRED FOR NAMES WITH SPACES.
## ORDER OF APPEARENCE DEFINES POST ID. STARTS WITH 1 (USED AS HOMEPAGE).
#create_pages=""                        ## SPACE SEPARATED NAMES.

## HIERARCHY OF MENUS TO CREATE. ENTRIES CAN BE EITHER A:
## * NUMBER THAT REFERS TO A POST ID;
## * LABEL ENDING WITH '(' THAT DEFINES A SUBMENU;
## * SPACE-PREFIXED ')' THAT CLOSES THE SUBMENU.
#create_menus=""                        ## POST_ID, SUBMENU_LABEL(, ) .

## PLUGINS INDEXED BY WordPress TO INSTALL (YOUR DEPENDENCIES).
## USUALLY THE NAME OF THE PLUGIN'S DIRECTORY IN wp-content/plugins.
#deps_plugin=""

## A THEME INDEXED BY WordPress TO INSTALL (YOUR THEME DEPENDENCY).
## style.css WILL REFER TO ITS PARENT IF $create_content CONTAINS "childtheme".
#deps_theme=""                            ## THEME OF YEAR KEPT IF EMPTY.

## PROFILE FOR AUTOMATED CHOICES (devel OR test). INTERACTIVE IF EMPTY.
#profile=""                               ## SEE HELP.

## ENABLE WordPress' WP_DEBUG OPTIONS. DEFINED IF LEFT EMPTY (SEE NEXT SECTION).
#wp_debug="true"                          ## OR false FOR NO DEBUG.

## COMMANDS TO eval AFTER SUCCESSFUL INSTALL.
## TO KEEP CONSISTENCY WITH INSTALLATION SETTINGS. USE ';' TO SEPARATE COMMANDS.
#post_install=""                          ## AVOID ' AND ESCAPE $ " (SEE printf)

## AVOID RUNNING USER DETECTION FOR MYSQLD BY SETTING AN EMPTY VALUE.
#user_mysqld=""                           ## LEAVE UNSET TO LET DETECTION OCCUR.

## SET HOW TO CONNECT WITH MYSQL DEAMON (DO NOT USE tcp:// PREFIX).
#hstprt_mysqld=""                         ## FORMAT IS HOST:PORT OR PATH (UNIX).

## MENU NAME, YOUR CHOICE
#menu_name="primary-menu"

## MENU LOCATION, DEPENDS ON YOUR THEME
#menu_location="primary"

## WORDPRESS LOCALE (FOR INSTANCE en_US)
#wp_locale=""

## ====================================================
## = DEFAULT MAIN VARIABLES IF NOT DEFINED EXTERNALLY =
## ====================================================

path_install=${path_install:="/var/www/wordpress"}
wp_debug=${wp_debug:="true"}
menu_name=${menu_name:="Main menu"}
menu_location=${menu_location:="primary"}

## ================================
## = HELPING GENERATED CONSTANTS  =
## ================================

## URL TO DOWNLOAD wp-cli.
readonly WPCLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
## PATH IN GUEST WHERE wp-cli WILL BE DOWNLOADED.
WPCLI_DIR="/var/www/"
## $path_install PARENT DIRECTORY.
readonly PATH_INSTALL_P="$(dirname "$path_install")"
## $path_install PLUGINS AND THEMES DIRECTORY.
readonly PATH_INSTALL_C="$path_install/wp-content"

## REGULAR EXPRESSION ARGUMENT FOR procname* functions.
readonly RE_PROC_httpd='(httpd|apache?)'
readonly RE_PROC_mysqld='mysqld(_safe)?'

## ===============
## = FANCY STUFF =
## ===============

readonly BP="  "                          ## BOT PREFIX (INDENTATION)
readonly BS="$CBE"                        ## BOT SKIN COLOR
readonly B_AWAKE="$BS(${CGY}｡${CCN}◕$BS‿${CCN}◕${CGY}｡$BS)${NORM}"
readonly B_HAPPY="$BS(${CGN}｡${CYW}^$BS‿${CYW}^${CGN}｡$BS)${NORM}"
readonly B_UPSET="$BS(${CRD}｡${CYW}⊗$BS˳${CYW}⊗${CRD}｡$BS)${NORM}"
readonly B_DYING="$BS(${CDG}｡${CYW}x$BS⁔${CYW}x${CDG}｡$BS)${NORM}"
readonly B_WAIT1="$BS(${CGY}｡${CGN}◑$BS˳${CGN}◑${CGY}｡$BS)${NORM}"
readonly B_WAIT2="$BS(${CWE}｡${CGN}◒$BS‿${CGN}◒${CWE}｡$BS)${NORM}"
readonly B_WAIT3="$BS(${CGY}｡${CGN}◐$BS‿${CGN}◐${CGY}｡$BS)${NORM}"
readonly B_WAIT4="$BS(${CBK}｡${CGN}◓$BS‿${CGN}◓${CBK}｡$BS)${NORM}"
readonly B_EMBRS="$B_WAIT1"               ## EMBARRASSED (AKA PEBKAC)


## TEST FOR (NON-POSIX?) binaries THAT MIGHT BE OVERLOADED LATER HERE
## AND SET VARIABLES (NAMED AS THE BINARY) TO THEIR FULLPATH.
for bin in base64 sudo wget git mysqladmin wp pbcopy; do
  path=$(type -p $bin 2>/dev/null) && declare $bin="$path"
done
## TEST FOR open OR xdg-open (linux).
for bin in open xdg-open; do
  path=$(type -p $bin 2>/dev/null) && declare open="$path"
done
## TEST FOR (CODE) EDITORS.
for bin in subl geany; do
  path=$(type -p $bin 2>/dev/null) && declare editor="$path"
done

## TELL BASH TO STOP ON ERROR.
set -e

## ==========================
## = ENFORCE BASIC SANITY =
## ==========================

function p_check_OS () {
## NO ARGUMENT NOR MEANINGFUL RETURN

  ## ARE httpd AND mysqld STARTED?        #XXX: ALSO FOR USER PERMISSIONS LATER
  for daemon in httpd mysqld; do          #TDL: SET IN A FUNCTION
    re_proc="RE_PROC_$daemon"
    varname="user_$daemon"
    test ! -z "${!varname+x}" && continue   ## SET FOR A dockerIZED DEAMON
    if users_daemon=($(procname2U ${!re_proc} | uniq)) &&
      test -n "${users_daemon[0]}"; then
      if (( ${#users_daemon[@]} >= 1 )); then  #XXX: CONSIDER ROOT + OTHER USER
        if [[ ${users_daemon[0]} == "root" ]]; then
          eval user_$daemon="${users_daemon[1]}"  #XXX: declare LIMITS SCOPE
        else
          eval user_$daemon="${users_daemon[0]}"
        fi
      fi
    else
      p_fatal 2 "username running ${LARG}$daemon${NORM}. "                   \
                  "I can't find it: is it ${LARG}started${NORM}?"
    fi
  done
  #TDL: IF $hstprt_mysqld IS SET, TRY CONNECTING WITH MYSQL CLIENT

  ## IS sudo AVAILABLE?
  if test -z "$sudo"; then
    test -z "$TERM" && p_fatal 2 "su requires a value for ${LARG}\$TERM$" \.
    function sudo () {
      if [[ "$1" == "-u" ]]; then
        shift; local usr="$1"; shift
      fi
      eval su --command \"$@\" $usr
    }
  fi

  ## IS php AVAILABLE? IS A MAILER CONFIGURED?
  php -v > /dev/null 2>&1 || p_fatal 2 "missing ${LARG}php" \.

  ## IS wget OR curl AVAILABLE?
  if test -z "$wget"; then
    curl --version > /dev/null 2>&1 && wget="curl -O" ||  {
      p_warn "I can't find ${LARG}wget" " nor ${LARG}curl" \.
      p_choice "Shall we continue?" 0 yes exit
      [[ $BOTASK_ANSWER == 1 ]] && exit $EXIT_UNUSABLE_SYS; }
  fi

  ## IS wp-cli AVAILABLE?
  if test -z "$wp"; then
    if test -x "$WPCLI_DIR/wp-cli.phar"; then
      wp="$WPCLI_DIR/wp-cli.phar"
    else
      p_choice "I can't find wp-cli in $WPCLI_DIR (${LARG}http://wp-cli.org${NORM}). \
 Can I download it from $WPCLI_URL ?" 0 yes exit
      [[ $BOTASK_ANSWER == 1 ]] && exit $EXIT_UNUSABLE_SYS
      run_as $user_httpd test ! -w "$WPCLI_DIR" &&
        echo "$WPCLI_DIR" not writable for $user_httpd &&
        exit $EXIT_UNUSABLE_SYS
      cd "$WPCLI_DIR"
      run_as $user_httpd $wget $WPCLI_URL
      run_as $user_httpd chmod +x wp-cli.phar
      cd -
      wp="$WPCLI_DIR/wp-cli.phar"
    fi
  fi
  ## ENSURE SAFER DIRECTORY CHANGES TYING WP TO $user_httpd
  wp="run_as $user_httpd $wp --path=$path_install"

  ## IS base 64 AVAILABLE?
  if test -z "$pwd_mysql""$pwd_wordpress" && test -z "base64"; then
    p_fatal 2 "${LARG}base64" "missing for password generation"
  fi

  ## IS GIT AVAILABLE?
  if test -n "$url_overlaygit" && test -z "$git"; then
    p_fatal 2 "${LARG}git" "missing clone your overlay ${USRV}$url_overlaygit" \.
  fi
}

## RETREIVE MENU INFOS
function menu_infos () {
## $1: slug, name, location[s] or whatever available (`$wp help menu list`).

  f=$1; [[ "$1" == "location" ]] && f="locations"   #XXX: I LOVE CONSISTENCY.
  $wp menu list --fields=$f --format=csv | tail -1
}

function p_check_variables () {
## NO ARGUMENT NOR MEANINGFUL RETURN

  ## AVOID WHITESPACE AND CAPITALS IN $sitename
  if [[ "$sitename" =~ [A-Z[:space:]?]+ ]]; then
    p_fatal 1 "argument (${USRV}$sitename" ") should be set"                   \
                " ${LARG}without caps nor space${NORM} " "for WordPress"
  fi
  ## OVERLAY READABLE IF IT EXISTS
  if test -n "$path_overlay"; then        #TDL: SET TO CANONICAL PATH?
    ## CHECK IF SET BUT NOT A DIRECTORY NOR READABLE
    if test ! -d "$path_overlay" || test ! -r "$path_overlay"; then
      p_fatal 1 "lacking access to directory " "${USRV}$path_overlay"
    fi
    ## CHECK IF SUBDIRECTORIES plugins AND themes EXIST AND READABLE
    for dir in plugins themes; do
      if test -d "$path_overlay/$dir"; then
        overlayP_content="$overlayP_content $dir"
        if test ! -r "$path_overlay/$dir"; then
          p_fatal 1 "lacking access to directory " "${CMPV}$path_overlay/$dir"
        fi
      fi
    done
    if test -z "$overlayP_content"; then
      p_fatal 1 missing either ${LARG}plugins or ${LARG}themes in "$path_overlay"
    fi
  fi
  ## SET URL TO WordPress? (eg: http://localhost:8888/my-project)
  test -z "$url" && url="http://$sitename:80/"
  ## SET LOGIN OF WordPress ADMIN?
  test -z "$admin_login" && admin_login="admin-$sitename"
  ## ARE REQUIRED VARIABLES SET?
  test -z "$email" && p_fatal 1 "missing value for ${LARG}email"
  test -z "$title" && p_fatal 1 "missing value for ${LARG}title"
  ## DOES $create_content HAVE PROPER VALUES?
  for c in "$create_content"; do
    if [[ "$c" != 'theme' ]] && [[ "$c" != 'childtheme' ]] &&
       [[ "$c" != 'plugin' ]] && test -n "$c"; then
      p_fatal 1 "missing string ${LARG}create_content" " holding '${LARG}theme"\
                "' and/or '${LARG}plugin" "' or nothing."
    fi
  done
  if [[ "$create_content" == *"childtheme"* ]] && test -z "$deps_theme"; then
    p_fatal 1 "missing parent theme name in ${LARG}deps_theme" \.
  fi
}

function p_check_basic_security () {    #TDL: CONTINUE
## NO ARGUMENT NOR MEANINGFUL RETURN

  ## IDEALLY PASSWORDS ARE IN A MODE 600 FILE SO THAT NO COMMAND LINE LEAKS THEM.
  ## CHECK $path_install DIRECTORY OWNED BY ROOT +STICKYBIT (PREVENT DAMAGE).
  ## APACHE: SET "ServerSignature Off" AND "ServerTokens Prod"
  ##          CHECK $path_install LISTING ?
  # ls -l /etc/httpd/modules | grep -Ei '(evasive|security)'
  #           OWASP CRS ?
  echo -n "";                             #XXX: REMOVE WHEN FUNCTION HAS BODY
}

function p_check_basic_pitfalls () {    #TDL: CONTINUE + SUPPORT VARIOUS HTTPD
## NO ARGUMENT NOR MEANINGFUL RETURN

  ## CHECK FOR COMMON OVERLOOK IN HTTPD CONFIGURATION
  local vendor_httpd="apache2"            #TDL: DETERMINE HTTPD SERVER RUNNING
  local config_file
  case "$vendor_httpd" in
    apache2)  ## APACHE CONFIG ERRORS
      local RE_A_Dir="(?s)<Directory[[:space:]+]$path_install>.*?</Directory>"
      local RE_A_AO=".*AllowOverride[[:space:]+]None"
      local config_httpd="/etc/apache2/sites-enabled/"  #TDL: DO BETTER
      ## RETREIVE CONFIG FILE FOR OUR INSTALL
      for f in $config_httpd*; do
        grep -Pazoq "$RE_A_Dir" "$f" && config_file="$f" && break
      done
      if test -n "$config_file"; then
        if grep -Pazo "$RE_A_Dir" "$config_file" | grep -q "$RE_A_AO"; then
          p_warn "With ${LARG}AllowOverride None" " in ${CMPV}$config_file"\
            ", at least permalinks won't work.\n\tChange 'None' for"\
            " ${LARG}FileInfo" " to avoid issues."
        fi
      fi
      ;;
    *)
      p_warn "I can't find the server's configuration ${LARG}http" \.
      ;;
  esac

  ## CHECK php HAS A MAILING SUBSYSTEM
  mailer_cmd=$(php -r \@phpinfo\(\)\; | grep sendmail_path | sed 's/^.*=>//') ||
    p_fatal 2 "lacking ability to execute 'php -r \@phpinfo\(\)' "
  MAILERS=(mail ssmtp postfix)
  for (( i=0; i<=${#MAILERS[@]}-1; i++)); do
    [[ "$mailer_cmd" == *${MAILERS[$i]}* ]] && break
  done
  if (( $i == ${#MAILERS[@]} )); then
    p_warn "php has no ${LARG}mailer " "configured!"
  fi

  ## CHECK FOR wp-cli UPDATES?
  [[ "$profile" != "test" ]] &&
    p_choice "I update ${CMPV}wp-cli${NORM} ?" 1 yes no && {
    if [[ $BOTASK_ANSWER == 0 ]]; then
      if [[ $(stat -c '%U' /usr/local/bin/wp) == "root" ]]; then
        $wp --allow-root cli update
      else
        $wp cli update                    #XXX: SHALL BE RUN AS $user_httpd
      fi
    fi
  }
  return 0
}

# ======================================================
# = THE SHOW IS ABOUT TO BEGIN : CHECK ARGUMENTS FIRST =
# ======================================================
echo
p_info "Hi ${CMPV}$(whoami)" "! I'm ${LARG}Wippy"    \.

## PARSE OPTIONS AND ARGUMENT + CHECK
for token in "$@"; do
  case "$token" in
    --help)   echo "$HELP"
              exit $EXIT_OK
              ;;
    --test)   ;&
    --devel)  test -n "$profile" &&
                p_fatal 1 "provide a single value for ${LARG}profile "         \
                            "${NORM}(profile=${USRV}$profile${NORM})."
              profile="${token:2}"
              continue
              ;;
    --*)      p_fatal 1 "provide a known option, not ${LARG}$token${NORM}. "   \
                          " Try: $0 --help"
              ;;
    *)        test -n "$sitename" &&
                p_fatal 1 "provide a single ${LARG}site name "                 \
                          "${NORM}(sitename=${USRV}$sitename${NORM})."
              sitename="$token"
              continue
              ;;
  esac
done
## NUMBER OF ARGUMENTS
if (( $# < 1 )) || test -z "$sitename"; then
  p_fatal 1 "provide exactly ${LARG}1 argument" "!. ${NORM}Start me as:"       \
            "\t$0 sitename\n\tor just run: $0 --help"
fi

p_check_OS                              ## BIN + CRED CHECKS
p_check_variables                       ## CONSISTENCY CHECKS
p_check_basic_security                  ## BARE MINIMUM CHECKS
p_check_basic_pitfalls                  ## COMMON ERRORS CHECKS

## =============
## = LAST CALL =
## =============

## USER REVIEW OF OUR CONFIG
p_info "I'm about to install WordPress for your website: ${USRV}$sitename" ".
\t${BP}Please have a last check on the configuration: "
for var in url email title description deps_plugin deps_theme admin_login      \
           pwd_wordpress wp_debug pwd_mysql hstprt_mysqld user_mysqld wp_locale\
           menu_name menu_location user_httpd path_install post_install
do
  echo -ne " $var:\t"
  if test -z "${!var}"; then
    echo -e "${CYW}no value${NORM}";
  else
    echo -e "${LARG}${!var}${NORM}";
  fi
done
## PHP SETTINGS
echo -ne "PHP mails with:"; test -n "$mailer_cmd" && echo "$mailer_cmd" || echo
$wp --info
## MORE VERBOSITY FOR THOSE IMPORTANT SETTINGS
for var in mysql wordpress; do
  varname="pwd_$var"
  if test -z "${!varname}"; then
    p_warn -n "I'm creating a new password for ${CMPV}$var" \.
  fi
done; echo
test -n "$url_overlaygit" && p_warn "I will clone repository: $url_overlaygit"
test -n "$create_content" && p_warn "I will create new: $create_content"
test -n "$path_overlay" && p_warn -n "I will link to your overlay for " && {
  echo $(ls --color -m $path_overlay/plugins/ $path_overlay/themes/ 2>/dev/null)
  }
test -n "$create_pages" && p_warn "I will create page(s): $create_pages"
test -n "$create_menus" && p_warn "I will create menu(s): $create_menus"

[[ "$profile" != "test" ]] && {
  p_choice "Let's go?" 0 yes exit
  [[ $BOTASK_ANSWER == 1 ]] && exit $EXIT_UNUSABLE_SYS
}

## ==============
## = HERE WE GO =
## ==============

## INSTALL OR UPDATE WordPress?
SKIP_INSTALL=/bin/false
if $wp core is-installed > /dev/null 2>&1; then
  ## INSTALLED: DISPLAY VERSION & ASK FOR APPROVAL TO MODIFY OR REPLACE
  p_warn "WordPress $($wp core version) ${LARG}is already installed" \.
  p_choice "What's your call?" 1 exit skip continue replace
  [[ $BOTASK_ANSWER == 0 ]] && exit $EXIT_UNUSABLE_SYS
  [[ $BOTASK_ANSWER == 1 ]] && SKIP_INSTALL=/bin/true
  [[ $BOTASK_ANSWER == 3 ]] && rm -rf "$path_install/*" #XXX: drop DONE @ wp db create
elif test ! -d "$path_install" && test ! -w "$PATH_INSTALL_P"; then
  ## $path_install's PARENT DIRECTORY NOT WRITABLE, HENCE BAIL
  p_fatal 2 "missing write privileges to ${LARG}$PATH_INSTALL_P"
else
  ## DOWNLOAD LATEST WordPress
  p_info "I'm downloading WordPress..."
  test -n "$wp_locale" && wp_locale="--locale=$wp_locale"
  $wp core download $wp_locale --force
fi

## THE MySQL PASSWORD NEEDS TO BE RESET (SPECIFIED OR GENERATED)
#XXX: ALLOW USING upstart BUT SHOULD BE EASILY ADAPTED TO systemd AND/OR initd
function reset_MySQL_password ()
## $1     : PASSWORD TO USE; LEAVE UNSET/EMPTY FOR SELF-GENERATION
## returns: LAST COMMAND'S SUCCESS
{
  if test -z "$1"; then
    ## GENERATE RANDOM PASSWORD
    passgen=$(head -c 10 /dev/random | $base64)
    pwd_mysql=${passgen:0:10}
  else
    pwd_mysql="$1"
  fi
  ## GENERATE RANDOM PIDFILE
  passgen=$(head -c 10 /dev/random | cksum | cut -d' ' -f1)
  pidfile_db=/tmp/${passgen:0:10}.pid

  ## RESTART MYSQL TO RESET THE PASSWORD
  db_procs=$(procname2Upca $RE_PROC_mysqld)
  if test -n "$db_procs"; then
    p_info "There is ${LARG}$(echo "$db_procs"|wc -l)" " mysqld processes: "
    echo "$db_procs"
    p_choice "I'd like to kill them all..." 0 service interact killall exit
    case "$BOTASK_ANSWER" in
      0)  run_as root service mysql stop  #TDL: systemctl OR service OR ..?
          p_waitWhile test -z \"'$(run_as root service mysql status | grep stop)'\"
          ;;
      1)  opt="-i"
          ;&                              #XXX: CASCADE
      2)  echo                            #XXX: AVOID OUTPUT OVERLAP
          runas_root killall $opt -r $RE_PROC_mysqld
          p_waitWhile test -n \"'$(procname2p \$RE_PROC_mysqld)'\"
          ;;
      3)  exit $EXIT_UNUSABLE_SYS
          ;;
    esac
  fi
  run_as root mysqld_safe --skip-grant-tables --pid-file="$pidfile_db" &
  p_waitWhile test ! -e $pidfile_db     #XXX: PIDFILE INSURES PROC IS READY
  run_as root mysql -u root -e "use mysql;
update user SET PASSWORD=PASSWORD(\"$pwd_mysql\") WHERE USER='root';
flush privileges;"
  p_success "password for mysql changed to: ${LARG}$pwd_mysql"
  run_as root $mysqladmin --password="$pwd_mysql" shutdown   #SEC: insecure
  p_waitWhile test -n \"'$(procname2p \$RE_PROC_mysqld)'\"
}

## RESET DATABASE PASSWORD ?
mysql -u root --password="$pwd_mysql" -e "use mysql;" 2>&1 >/dev/null || {
  p_warn "${LARG}I Cannot connect to MySQL as root..."
  p_choice "What should I do about the password for MySQL?" 0 reset exit
  [[ $BOTASK_ANSWER == 1 ]] && exit $EXIT_UNUSABLE_SYS
  [[ $BOTASK_ANSWER == 0 ]] && reset_MySQL_password "$pwd_mysql"
}

## DATABASE SHOULD BE WORKING FOR ALL THAT WE DO HEREAFTER
if test -n "$user_mysqld" && run_as root service mysql status | grep stop; then
  p_info "I ${LARG}start mysqld!"
  run_as root service mysql start
fi

## CREATE BASE WordPress CONFIGURATION
if [[ ! $SKIP_INSTALL ]] ; then
  p_info "I initiate WordPress configuration :"
  run_as $user_httpd rm -f "$path_install/wp-config.php"
  test -n "$hstprt_mysqld" && db_="--dbhost=$hstprt_mysqld"
  $wp core config --dbname="$sitename"    \
                  --dbuser=root           \
                  --dbpass=$pwd_mysql     \
                  $db_                    \
                  --skip-check            \
                  --extra-php <<< "
  define('WP_DEBUG', $wp_debug);
  define('WP_DEBUG_LOG', $wp_debug);"

  ## CREATE DATABASE
  $wp db create > /dev/null 2>&1 || {
    if [[ "$profile" == "test" ]]; then
      BOTASK_ANSWER=1
    else
      p_warn "The WP database already exists, I need to ${LARG}delete it!" \.
      old_sql="old-$sitename.sql"
      p_choice "Shall I back it up? ${CMPV}$(pwd)/$old_sql ?" 0 yes no  #TDL: SUPPORT KEEPING THE DB
    fi
    if [[ $BOTASK_ANSWER == 0 ]]; then
      $wp db export "./$old_sql"            ## CONFIRMS TO stdout
    fi
    $wp db drop --yes
    p_info "I create the WP database ${USRV}$sitename"
    $wp db create
  }

  ## INSTALL WordPress CORE
  if test -z "$pwd_wordpress"; then
    ## GENERATE RANDOM PASSWORD
    passgen=`head -c 10 /dev/random | base64`
    pwd_wordpress=${passgen:0:10}
  fi
  p_info "and now I install !"
  $wp core install    --url="$url"                \
                      --title="$title"            \
                      --admin_user="$admin_login" \
                      --admin_email="$email"      \
                      --admin_password="$pwd_wordpress"
  $wp option update blogdescription "$description"
  ## REMOVING DEFAULT PLUGINS AND THEMES.   #TDL POSTPONE TO REMOVE ONLY DEFAULT UNUSED CONTENT
  for content in plugin theme; do
    for c in $($wp $content list --fields=name --format=csv |grep -v '^name$'); do
      p_info "I delete basic $content ${LARG}$c"
      $wp $content delete "$c" || p_info "no worries."
    done
  done

fi          #XXX if ! $SKIP_INSTALL

## INSTALL WordPress PLUGINS AND THEMES FROM $deps_plugins
for content in plugin theme; do
  varname="deps_$content"
  for c in ${!varname}; do
    p_info "I install your dependency $content ${LARG}$c"
    $wp $content install $c --activate
  done
done

## MANAGE VARIOUS (COMPATIBLE) SCENARIOS AND ACTIVATE PLUGINS OR THEME.
##
## SCENARIO: YOU'RE A GOOD DEV AND YOUR PROJECT IS UNDER GIT VERSIONING
## CLONE GIT OVERLAY PLUGINS AND THEMES
if test -n "$url_overlaygit"; then
  [[ "$profile" != "test" ]] && {
#    [[ "$profile" == "devel" ]] && BOTASK_ANSWER=0 ||
    p_choice "Do you develop the files in the git repository?" 0 yes no #TDL: CREATE A DEV/PROD_TEST SETTING
    if [[ $BOTASK_ANSWER == 0 ]]; then
      run_as root chown $(whoami) "$PATH_INSTALL_C"  #XXX: ALREADY GROUP WRITABLE
    else
      git="run_as $user_httpd $git"
    fi
    p_info "I clone your overlay git in ${CMPV}target_dir"
    cd "$PATH_INSTALL_C"                  #XXX: ACCESSIBLE IN BOTH CASES
    $git clone --progress "$url_overlaygit" #XXX: NO cd, TARGET DIR MUST BE EMPTY
    cd -
    p_success "Make sure ${LARG}privileges" " are correct."
  }
fi
##
## HANDLE SCENARIOS WITH CUSTOM PLUGIN(S) AND/OR THEME(S)
for content in plugin theme; do
  dirname_cont="$content"s
  dirname_dest="$dirname_cont/$sitename"
  path_cont="$PATH_INSTALL_C/$dirname_cont"
  path_dest="$PATH_INSTALL_C/$dirname_dest"
  ## IF $PATH_INSTALL_C IS SET: CARRY ON ANYWAY FOR OTHER DEVEL/TEST?
  if test -e "$path_dest"; then
    p_warn "${CMPV}$dirname_dest" " already exists:"
    ls -la "$path_dest"
    p_choice "Shall I continue?" 0 yes passer exit  #TDL: destroy
    [[ $BOTASK_ANSWER == 2 ]] && exit $EXIT_UNUSABLE_SYS
    [[ $BOTASK_ANSWER == 1 ]] && continue
  fi
  ## SCENARIO: DEVELOPING (E.G: FROM GENERATED DEV-READY FILES ONLY)
  ## CREATE TARGET FOLDERS IF NEEDED AND DEFAULT FILES
  if [[ "$create_content" == *"$content"* ]]; then
    p_info "I create ${CMPV}$dirname_dest/"
    run_as root chown $(whoami) "$path_cont"  #XXX: EXPECTS chmod g+w
    mkdir -p "$path_dest"                 #XXX: $(whoami) OWNS AND THUS CAN EDIT
    if [[ "$create_content" != *"childtheme"* ]]; then
      cp -r "$content/"* "$path_dest/"
    else
      cp -r "childtheme/"* "$path_dest/"
      ln -s "$path_dest/screenshot.png" "$path_dest/$sitename-screenshot.png"
      sed -i -- "s/myBAR/$deps_theme/g" "$path_dest/"*
    fi
    sed -i -- "s/myFOO/$sitename/g" "$path_dest/"*;
    sed -i -- "s/myFOO/$sitename/g" "$path_dest/languages/"*;
    ## ACTIVATE OVERLAYED PLUGINS AND/OR THEMES
    p_info "I activate and install the ${LARG}$content ${USRV}$sitename"
    $wp $content activate "$sitename"
  fi
  ## SCENARIO: TESTING (E.G: VIRTUAL MACHINE WITH SHARED FOLDER)
  ## CREATE SYMLINKS TO FOLDERS IF NEEDED
  if test -n "$path_overlay" && test -d "$path_overlay/$dirname_cont"; then
    for dir in "$path_overlay/$dirname_cont/"*; do
      target=$(basename $dir)
      if test -d "$dir"; then             #XXX: $dir ENDS WITH * IF DIR IS EMPTY
        p_info "I link ${CMPV}$path_cont/$target -> $dir"
        run_as $user_httpd ln -sf "$dir" "$path_cont/"
        $wp $content activate $target ||
          p_fatal 2 "unactivable $content ${USRV}$target"
      fi
    done
  fi
done

BOTASK_ANSWER=1
[[ $SKIP_INSTALL ]] && p_choice "skip deletion of toy-articles?" 0 yes no
if [[ $BOTASK_ANSWER == 1 ]]; then
  ## CLEANUP EXEMPLE POSTS                  #XXX: A DELETED POST ID IS KEPT BY WP.
  p_info "I delete toy-articles:"
  $wp post delete 1 --force                 ## POST1: ARTICLE AND ITS COMMENT
  $wp post delete 2 --force                 ## POST2: DUMMY PAGE
fi

## CUSTOMISING UNLESS YOU CREATE YOUR OWN (CHILD)THEME WHICH SHOULD DO ALL
if [[ "$create_content" != *theme* ]]; then
  BOTASK_ANSWER=1
  [[ $SKIP_INSTALL ]] && p_choice "skip customisation?" 0 yes no
  if [[ $BOTASK_ANSWER == 1 ]]; then

    ## CREATE PAGES
    test -n "$create_pages" && p_info "I create your pages ${USRV}$create_pages"
    eval list=($create_pages)
    for (( i=0; i<=${#list[@]}-1; i++)); do
      $wp post create --post_type=page --post_status=publish --post_title="${list[i]}"
      if (($i == 0)); then
        ## CHANGE HOMEPAGE
        p_info "I set the homepage"
        $wp option update show_on_front page
        $wp option update page_on_front 3
      fi
    done

    ## CREATE MENUS                         #TDL: SUPPORT SUBMENUS
    p_info "I create the main menu (at $menu_location) linked to pages:"
    $wp menu create "$menu_name" ||
      p_fatal 2 "missing name free for use. Those already in use are:
        $NORM$(menu_infos name)"
    $wp menu location assign "$menu_name" "$menu_location" ||
      p_fatal 2 "missing supported location. Choices are:
        $NORM$(menu_infos location)"
    test -n "$create_menus" && p_info "I create your menus ${USRV}$create_menus"
    for m in $create_menus; do
      $wp menu item add-post "$menu_name" $((m+2))
    done

  fi
fi

## CREATE FAKE POSTS?
[[ "$profile" != "test" ]] && {
  p_choice "Shall I create a few fake articles?" 1 yes no
  if [[ $BOTASK_ANSWER == 0 ]]; then
    $wget http://loripsum.net/api/5 | $wp post generate --post_content --count=5
  fi
}

BOTASK_ANSWER=1
[[ $SKIP_INSTALL ]] && p_choice "skip setting permalinks structure, category_base, and tag_base?" 0 yes no
if [[ $BOTASK_ANSWER == 1 ]]; then
  ## SET PERMALINKS TO /%postname%/
  p_info "I set permalinks structure"
  $wp rewrite structure "/%postname%/" --hard
  $wp rewrite flush --hard

  ## CATEGORY AND TAG BASE UPDATE
  $wp option update category_base theme
  $wp option update tag_base sujet
fi

## DO ANY POST-INSTALLATION COMMANDS
for cmd in "$post_install"; do
    p_info "I launch your post-install command: ${USRV}$cmd"
    eval $cmd
done


## ==================================
## = SETUP READY-TO-DEV ENVIRONMENT =
## ==================================

## PUT PROJECT UNDER Git VERSION CONTROL
[[ "$profile" != "test" ]] && {
#  [[ "$profile" == "devel" ]] && BOTASK_ANSWER=0 ||
  p_choice "Shall I put this project ($pathtoproject) under Git?" 1 yes no
  if [[ $BOTASK_ANSWER == 0 ]]; then
    cd "$pathtoproject"
    $git init    # git project
    $git add -A  # Add all untracked files
    $git commit -m "Initial commit"
    cd -
  fi
}

## OPEN THE SITE WITH YOUR DEFAULT BROWSER
[[ "$profile" != "test" ]] && {
  p_choice "Should I start your browser?" 1 yes no
  if [[ $BOTASK_ANSWER == 0 ]]; then
    # Open in browser
    $open $url
    $open "${url}wp-admin"
  fi
}

## OPEN THE SOURCE FILES WITH YOUR EDITOR
[[ "$profile" != "test" ]] && {
#  [[ "$profile" == "devel" ]] && BOTASK_ANSWER=0 ||
  p_choice "Should I start your editor ?" 1 yes no
  [[ $BOTASK_ANSWER == 0 ]] && $subl "$pathtoproject"
}

## OPEN THE SOURCE FILES WITH
[[ "$profile" != "test" ]] && {
  p_choice "Should I start your file manager ?" 1 yes no
  [[ $BOTASK_ANSWER == 0 ]] && $open "$pathtoproject"
}

## =====================
## = THAT'S ALL FOLKS! =
## =====================

## SHOW INSTALL SUMMARY
p_success "Installation done!"
echo
echo -e "site URL     :  ${USRV}$url${NORM}"
echo -e "admin's login:  ${CMPV}$admin_login${NORM}"
echo -e "password     :  ${CMPV}$pwd_wordpress${NORM}"
if test -n "$pbcopy"; then
  ## COPY PASSWORD IN CLIPBOARD
  echo $pwd_wordpress | $pbcopy > /dev/null 2>&1
  p_info "I copied the password in the clipboard."
  ## LET THE USER HANDLE CLIPBOARD DATA
  p_choice "Did you save it for later?" 0 yes no
  [[ $BOTASK_ANSWER == 0 ]] && p_info "no worries ;)"
fi
echo -e "mysql login:  ${CMPV}root${NORM}"
echo -e "password   :  ${CMPV}$pwd_mysql${NORM}"
if test -n "$pbcopy"; then
  ## COPY PASSWORD IN CLIPBOARD
  echo $pwd_mysql     | $pbcopy  > /dev/null 2>&1
  p_info "I copied the password in the clipboard."
  ## LET THE USER HANDLE CLIPBOARD DATA
  p_choice "Did you save it for later?" 0 yes no
  [[ $BOTASK_ANSWER == 0 ]] && p_info "no worries ;)"
fi
p_info "see you!"
echo
