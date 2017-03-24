#!/bin/bash
#
##
## AUTHOR: frederic Delaunay (fd@manymakers.fr) 2016
##
## THIS SCRIPTS EXISTS TO STAY COMPATIBLE WITH SYSV (Linux/MacOS/MinGW/..) AND
## INSTALL VirtualBox guest additions IN SYSTEMS NOT PACKAGING IT.
##

if test -z "${BASH_SOURCE[0]}"; then
  read -p '$BASH_SOURCE support required. Press Enter to continue.'
elif test -z "$GEN_VAGRANT_DEFINED"; then
  GEN_VAGRANT_DEFINED=:
  ## CAN DO OUR STUFF AND AS PEDANTIC AS TO STOP ON ERROR
  source $(dirname ${BASH_SOURCE[0]})/../base/prompted.sh
  [[ "$0" != /bin/bash ]] && set -e       ## CATCH ERRORS IN YOUR OWN SCRIPTS

function ask_defineIfUndef () {
  #$1 : name of variable
  local var="$1"
  if [[ -z "${!var}" ]]; then
    read -r -p $"${CRD}The ${NORM}${LARG}\$$var ${CRD}variable should be defined. ${NORM}Your value? > " $REPLY ||
    p_fatal $EXIT_USER_ABORT "You choosed to abort."
    declare $1=$REPLY
  fi
}

CONFIG_FILE="./my_$(basename $0)"
## ESSENTIAL VALUES
source $CONFIG_FILE
if ! ( [[ -f "$CONFIG_FILE" ]] && [[ -r "$CONFIG_FILE" ]] ); then
  p_choice "missing '$CONFIG_FILE', try interactive mode?" 1 yes abort
  [[ $BOTASK_ANSWER == 1 ]] && exit $EXIT_EXIT_USER_ABORT
fi
ask_defineIfUndef shared_folder_SRC
ask_defineIfUndef shared_folder_TRG
ask_defineIfUndef host
[[ "$host" =~ [A-Z[:space:]?]+ ]] &&      #XXX NO SPACE ALLOWED
  p_fatal $EXIT_INVALID_ARGUMENT "$USRV\$host " "${LARG}has capital chars or space."

## DEFAULT VALUES
#extra_packages=""
#VBoxPath=${VBoxPath:-"/c/Program Files/Oracle/VirtualBox/"}
IP_Addr=${IP_Addr:-"192.168.2.2"}
MYVAGRANTBASE=${MYVAGRANTBASE:-"debian/jessie64\\\";
 config.vm.box_version=\\\"<8.7"}         ## FOR VirtualBox <= 5.1"
MYVAGRANTBOX=${MYVAGRANTBOX:-"jessie-e2gf"}

################################################################################
##   DO NOT MODIFY FROM HERE ON                                                #
################################################################################
set -e

##
## GENERIC HELPERS
##
noStdE='2>/dev/null'
noStdOE='2>&1>/dev/null'
notInPath="has not been installed or hasn't been installed in its standard location.
Please add the correct path to your PATH variable."

## RUN COMMAND AND EXIT WITH A MESSAGE ON FAILURE (COMMAND RETURNS != 0)
function do_fatal ()
  ## $1:  command
  ## $2:  same as echo (message will be prefixed)
{                    #TDL: SWAP $2(TO REWRITE AS OBJECTIVE) AND $1, TO BE ABLE TO OUTPUT "STEP NUMBER - OBJECTIVE" WITH --list (--show TO BECOME --list-cmds)
  if test $STEP -le $STEP_SEEN; then
    [[ $DRY_RUN == "true" ]] && {
      echo -e "$LARG--- STEP $STEP ---$NORM\n$1"
      STEP=$((STEP+1))
      STEP_SEEN=$((STEP_SEEN+1))
      return 0
    }
    BP="STEP ${LARG}$STEP${NORM} "
    B_UPSET="FATAL ERROR:"
    eval $1 || p_fatal $EXIT_FATAL_ERROR "( [[ $1 ]] FAILED )\n${CRD}${LARG}$2${NORM}."
    echo -e "$CCN--- STEP $STEP SUCCEEDED ---$NORM" >&2
    STEP=$((STEP+1))
  fi
  STEP_SEEN=$((STEP_SEEN+1))
  return 0
}

##
## THE SCRIPT'S BUSINESS
##

function help () {
  echo -e "\n${CLARG}usage:${CNORM}
  $0 [options] step_or_keyword

${CLARG}steps:${CNORM}
  Represents a part of the install sequence. The step allows restarting that sequence at a specific part.
  There is no default step: you can run as \`${CLARG}GF_KEY=${CNORM}<YOUR_GF_KEY>${CLARG} 0${CNORM}\` (replacing <YOUR_GF_KEY>) to start the install process.

${CLARG}keywords:${CNORM}
  ${CYW}help$NORM     this help;
  ${CYW}clean$NORM    cleans all downloads or generated files, next run will require starting at step 0;
  ${CYW}destroy$NORM  destroys the VM but keep all downloads or generated files;
  ${CYW}wipe-out$NORM erases the VM, all downloads or generated files, next run will require starting at step 0.
  ${CYW}recover$NORM  recover our successfully installed VM. This allows you to skip all install steps to get the VM up and running.

${CLARG}options:${CNORM}
  ${CYW}--show$NORM   show the commands to be run but do not perform them;

${CLARG}Post-install note:${CNORM} vagrant to be run as:
  VAGRANT_VAGRANTFILE=$vagrantfile vagrant
"
}

function clean () {
  rm -f ./VB_web_out.html
  rm -f ./VB_filename
  rm -f ./VB_guestAdditions.iso
  echo "Cleaned all files."
}

function destroy () {
  vagrant halt -f
  vagrant destroy -f
  rm -f "$vagrantfile"
}

function wipe-out () {
  destroy
  clean
}

function recover () {
  if vagrant box list | grep "$MYVAGRANTBOX" >/dev/null; then
    vagrant init "$MYVAGRANTBOX" &&
    echo "
Vagrant.configure(2) do |config|
  config.vm.box = \"$MYVAGRANTBOX\"
  config.vm.provider \"virtualbox\" do |v|
    v.name = \"$MYVAGRANTBOX\"
  end
end" > Vagrantfile &&
    VAGRANT_VAGRANTFILE="Vagrantfile" vagrant up --no-provision &&
    echo -e "---
    Now ${CYW}${CLARG}you can forget about install.sh${CNORM} and simply run \`vagrant halt\` or \`vagrant up\`."
  else
    p_fatal $EXIT_UNUSABLE_SYS "$MYVAGRANTBOX is not available. Did the last step complete successfully?"
  fi
}

VBoxURL="https://download.virtualbox.org/virtualbox"

## EXTRAVAGRANTZA *\o/* : PREPARE EDITING OUR TEMPLATE FILE FROM USER VARIABLES

ExtraVagrant_BASE="$MYVAGRANTBASE"
ExtraVagrant_ADDR="$IP_Addr"
#XXX: $ExtraVagrant_PROV IS UNQUOTED IN TEMPLATE SO CONTROL OPERATORS REQUIRED
## USE debconf-set-selections TO AVOID ENTERING PASSWORDS AT PACKAGE INSTALL
    # cd /etc/apache2/ &&
    # cp /vagrant/website-apache2.conf ./sites-available/ &&
    # ln -sf ../sites-available/website-apache2.conf  ./sites-enabled/ &&
    # ln -sf ../mods-available/ssl.load               ./mods-enabled/ &&
    # rm -f ./sites-enabled/000-default.conf;
ExtraVagrant_PROV="
    debconf-set-selections <<< \'mysql-server mysql-server/root_password password your_password\';
    debconf-set-selections <<< \'mysql-server mysql-server/root_password_again password your_password\';
    apt-get -y install git apache2 mysql-server php5 php5-mysql $extra_packages;

    chown vagrant:www-data  /var/www/;
    chmod g+w               /var/www/;
    chmod +t                /var/www/;

    ./guest_install.sh

    service apache2 restart"
if test -z "$ExtraVagrant_SHRF"; then
  if test -z "$shared_folder_SRC" || test -z "$shared_folder_TRG"; then
    p_fatal $EXIT_UNUSABLE_SYS '$shared_folder_SRC or $shared_folder_TRG is unset or empty!'
  else
    ExtraVagrant_SHRF='config.vm.synced_folder
  \"$shared_folder_SRC\",
  \"$shared_folder_TRG\",
  group: \"www-data\", mount_options: [\"dmode=775,fmode=664\"],
  type: \"virtualbox\"'
  fi
fi

vagrantfile="Vagrantfile.$host"
export VAGRANT_VAGRANTFILE="$vagrantfile" ## AVOID INCLUDING PARENT Vagrantfile

DRY_RUN=0
STEP_SEEN=0
STEP="$1"
KEYWORDS=(help clean destroy wipe-out)

if test "$STEP" == "--show"; then
  DRY_RUN="true"                          #XXX SEE do_fatal
  shift; STEP=$1
fi
for (( i=0; i<=${#KEYWORDS[@]}-1; i++ )); do
  [[ "$STEP" == ${KEYWORDS[$i]} ]] &&
    arg_is_keyword="true"
done
if test -z "$arg_is_keyword" && ! [[ "$STEP" =~ ^-?[0-9]+$ ]]; then
  help
  p_fatal $EXIT_INVALID_ARGUMENT "argument '$' is not a number, nor an option, nor in [ ${KEYWORDS[*]} ]"
fi

##
## PERFORM ACTION ASSOCIATED WITH KEYWORD, OR RUN INSTALL SEQUENCE FROM $STEP
## STEPS'COMMANDS SHOULD NO LONGER EXPECT TO SHARE VARIABLES (POSSIBLE SKIPPING)
## THUS, USE FILES TO STORE DATA ACROSS STEPS AND RUNS.
##

if test -n "$arg_is_keyword"; then
  $STEP $0 $@
  exit 0
fi

## TEST ENV
setup_prepare $0 $@

## TEST BINARIES
do_fatal "vagrant --version $noStdOE" "vagrant $notInPath"
eval "VBoxManage --version $noStdOE" || {
  PATH="$PATH:$VBoxPath"
  do_fatal "VBoxManage --version $noStdOE" "VirtualBox $notInPath"
}
do_fatal "curl --version $noStdOE" "curl $notInPath"
do_fatal "sed --version $noStdOE" "sed $notInPath"

## CREATE OUR VAGRANTFILE IF NOT PRESENT
do_fatal "if test ! -f $vagrantfile; then cp $vagrantfile.template $vagrantfile; fi"

## GET VirtualBox GuestAdditions FOR THE CURRENT VERSION
VB_version=$(do_fatal "VBoxManage --version | sed s/[[:alpha:]_].*//" "could not retreive VirtualBox version")
do_fatal "curl -ksS $VBoxURL/$VB_version/ -o VB_web_out.html" "could not retreive file list on VirtualBox website"
do_fatal "cat ./VB_web_out.html | sed -n s/.*\"\\\(VBoxGuestAdditions_${VB_version}.iso\\\)\".*/\\\1\ /p > VB_filename" "could not retreive VirtualBox download filename for version $VB_version"
do_fatal "if test ! -f VB_guestAdditions.iso; then echo \"Downloading VirtualBox Guest Additions from $VBoxURL/$VB_version/\$(cat VB_filename)\";
 curl -k --progress-bar $VBoxURL/$VB_version/\$(cat VB_filename) -o VB_guestAdditions.iso; fi" "could not download Guest Additions from VirtualBox website"
## EDIT $vagrantfile TO ADD BASE BOX AND IP ADDRESS
do_fatal "VF=\$(cat $vagrantfile.template) &&
   VF=\"\${VF/\#EXTRAVAGRANT_BASE/\\\"$ExtraVagrant_BASE\\\"}\" &&
 echo \"\${VF/\#EXTRAVAGRANT_ADDR/\\\"$ExtraVagrant_ADDR\\\"}\" > $vagrantfile" "huh?"
## GET THE GUEST SYSTEM IMAGE. THE PROVISION STEP INSTALLS Guest Additions BUT
## THOSE REQUIRE A REBOOT TO TAKE EFFECT.
do_fatal "vagrant up --no-provision" "creating the VM could not complete."
do_fatal "VF=\$(cat $vagrantfile) &&
 echo \"\${VF/\#EXTRAVAGRANT_PROV/$ExtraVagrant_PROV}\" > $vagrantfile" "huh?"
do_fatal "vagrant provision" "provisioning the VM could not complete."
do_fatal "vagrant halt" "stopping VM failed"

## EDIT $vagrantfile TO ADD SHARED FOLDERS: NO MORE rsync THANKS TO Additions
do_fatal "VF=\$(cat $vagrantfile) &&
 echo \"\${VF/\#EXTRAVAGRANT_SHRF/$ExtraVagrant_SHRF}\" > $vagrantfile" "huh?"
do_fatal "vagrant up" "could not restart the VM with Guest Additions installed."

## GET Wippy FOR IN THE GUEST, SET PRIVILEGES AND INSTALL WordPress WITH Wippy
setup_customise $0 $@

## PACKAGE THE GUEST, JUST IN CASE.
#XXX ZERO-OUT REMAINING SPACE FOR COMPRESSION OPTIMISATION
do_fatal "vagrant ssh -c 'sudo apt-get clean &&
  sudo dd if=/dev/zero of=/REMAINING_SPACE bs=1M;
  sudo rm /REMAINING_SPACE' &&
vagrant package --output $host.vagrant-box --vagrantfile ./Vagrantfile.$host &&
vagrant box add -f $MYVAGRANTBOX $host.vagrant-box" "could not package the box"

do_fatal "test -f $MYVAGRANTBOX &&
vagrant init $MYVAGRANTBOX &&
vagrant up" "could not find file $MYVAGRANTBOX or use this newly packaged box"

#TDL: Automatize
setup_finalise $0 $@

fi          #XXX test -z "$GEN_VAGRANT_DEFINED"
