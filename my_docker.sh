#!/bin/bash

# KEEP OUR SOURCES AS SAFE AS POSSIBLE
canonical_path=$(cd ${0%/*} && echo $PWD)
if test ! -f "${canonical_path}/base.sh"; then
  echo "$0 depends on ${canonical_path}/base.sh which cannot be found. Bye."
  exit -1
fi
source ${canonical_path}/base.sh

test_bin 1 docker

# SET OUR BEAUTIFUL PROMPT
BP='- '

function echo_run ()
{
  echo "NOW RUNS: $@"
  "$@"
}

function val_from_userOrArgs ()
  # $1    : bot_argOrChoice() 2 ARGUMENT (I.E: STRING FOR bot_choice)
  # $2-n  : bot_argOrChoice() LIST OF VALUES FROM WHICH TO PICK 1ST ITEM
  # return: 1 IF VALUE RETREIVED FROM $2-n, 0 OTHERWISE (DON'T ELICIT shift ON ERROR)
  # exit  : ON USER REQUEST
{
  #XXX bot_argOrChoice RETURNS 1 IF VALUE TAKEN FROM ARGUMENTS (SO shift AFTER)
  value=$(bot_argOrChoice 0 "$@") ||  if [[ "$?" == "1" ]]; then
	echo "$value"; return 1
  fi;
  [[ "$value" == "abort" ]] && exit $EXIT_USER_ABORT
  echo "$value"; return 0
}

##
## FUNCTIONS RETURN BY ECHO
##
function get_list_of ()
{
  if 	[[ "$1" == "containers" ]] 	||
	[[ "$1" == "networks" ]] 	||
  	[[ "$1" == "volumes" ]]		||
	[[ "$1" == "images" ]] 
    then
	type="${1:: -1}"
  else bot_fatal $EXIT_INVALID_ARGUMENT "valid argruments in $FUNCNAME($@)"
  fi
  docker $type list $2
}

function get_imageORcontainer_setting ()
# $1: container_name or ID
# $2: arguments to jq
# $3-n: setting(s) name
{
  for s in "${@:3}"; do
	docker inspect $1 | jq $2 '.[0].'$s	#TDL see inspect -f
  done
}

##
## FUNCTIONS RETURN BY STATUS, NOT BY ECHO
##

function bot_backup_image ()
{
  get_list_of images -a
  img=$(val_from_userOrArgs '"Which image to save?" 0 abort $(get_list_of images -aq)' $@) || shift
  host_file="${img}-image-$(date +%Y%m%d).tar"
  bot_choice "proceed with creating $host_file from $img ?" 1 yes no;
    [[ $BOTASK_ANSWER != 0 ]] && exit $EXIT_USER_ABORT
  echo_run docker save -o $host_file $img
}

function bot_restore_image ()
{
  while : ; do
    read -rp "Where is the image to restore? > " image &&
    {
      echo_run docker load < $image || return $EXIT_UNKNOWN
    } || return $EXIT_USER_ABORT 
  done
  get_list_of images 
  echo 'rename it with `docker tag ID NAME`'
  return $EXIT_OK 
}

function bot_update_image ()
{
  docker images
  imgID=$(val_from_userOrArgs '"which image ID?" 0 abort $(get_list_of images -aq)' $@) || shift
  contID="updating-${imgID}"
  repo="manymakers"
  echo_run docker run -t --name $contID $imgID /bin/bash -c 'apt-get update && apt-get -y dist-upgrade && apt-get -y clean && apt-get -y autoclean' &&
    read -rp "1-liner commit message? > " commit &&
    echo_run docker commit -m \"$commit\" $contID $repo/$imgID:$(date +%Y%m%d) &&
    return $EXIT_OK
  # NO PUSH TO REPOSITORY YET
}

function bot_show_image ()
{
  get_list_of images -a
  image=$(val_from_userOrArgs '"Which image?" 0 abort $(get_list_of images -aq)' $@) || shift
  get_imageORcontainer_setting $image "-c" Config
}

function bot_backup_container ()
{
  echo "not yet"
  return $EXIT_OK
}

function bot_update_container ()
{
  echo "not yet"
  return $EXIT_OK
}

function bot_show_container ()
{
  get_list_of containers -a
  container=$(val_from_userOrArgs '"Which container?" 0 abort $(get_list_of containers -aq)' $@) || shift
  get_imageORcontainer_setting $container -c Config.ExposedPorts Config.Cmd Config.Volumes
  get_imageORcontainer_setting $container " " Mounts

  return $EXIT_OK
}

function bot_backup_volume ()
{
  get_list_of containers -a
  cont=$(val_from_userOrArgs '"Data volume of which container?" 0 abort $(get_list_of containers -aq)' $@) || shift
  # NEW CONTAINER MOUNTING pwd TO RECEIVE BACKUP
  eval image=$(get_imageORcontainer_setting $cont "-M -a" Config.Image)	#XXX HAS JSON "
  guest_dir_target="/backupDir"
  host_file="$guest_dir_target/${cont}-data-$(date +%Y%m%d).tar"
  while : ; do
    guest_dir_source=$(val_from_userOrArgs '"Which directory to backup on container $cont?" 0 abort /var/lib/mysql' $@) || :	#TDL FAILS ON DEFAULT!
    guest_dir_source="$guest_dir_source/"
    if docker run --rm --volumes-from $cont $image /bin/bash -c "echo ---- CONTENTS OF $guest_dir_source ---- ; ls $guest_dir_source"; then
	bot_choice "proceed with creating $host_file from $guest_dir_source ?" 1 yes no;
        bot_choice "proceed with creating $host_file from $guest_dir_source ?" 1 yes no;
        [[ $BOTASK_ANSWER == 0 ]] && break
        exit $EXIT_USER_ABORT
    fi
  done
  echo_run docker run --rm --volumes-from $cont -v $(pwd):"$guest_dir_target" $image tar --totals -cf "$host_file" "$guest_dir_source"
}

function bot_show_volume ()
{
  get_list_of volumes
  volume=$(val_from_userOrArgs '"Which volume?" 0 abort $(get_list_of volumes -q)' $@) || shift
  get_imageORcontainer_setting $volume -c Config
  return $EXIT_OK
}

function bot_show_network ()
{
  get_list_of networks --no-trunc
  names=()
  for n in $(get_list_of networks -q); do
	names+=($n)
  done
  net=$(val_from_userOrArgs '"Which network?" 0 abort $names' $@) || shift
  
}


# ASK for the action (prefix with integer to avoid collision)
COMMANDS="service show backup update restore"
command=$(val_from_userOrArgs '"What to do with docker?" 0 abort $COMMANDS' $@) || shift
case "$command" in
 abort)	sh -c "exit $EXIT_USER_ABORT"	## sets $?
 ;;
 service)
	action=$(val_from_userOrArgs '"which action?" 0 abort start stop' $@) || shift
	$command docker $action
	systemctl | grep docker
 ;;
 backup) ;&
 update) ;&
 restore)
	type=$(val_from_userOrArgs '"What to $command?" 0 abort image container volume' $@) || shift
	bot_${command}_${type} $@
 ;;
 show)
	type=$(val_from_userOrArgs '"What to $command?" 0 abort image container volume network' $@) || shift
	bot_${command}_${type} $@
 ;;
 *)	bot_fatal $EXIT_INVALID_ARGUMENT "a valid argument.${NORM} WTF is '$command'? use any of ${LARG} $COMMANDS ${NORM} please..."
 ;;
esac

exit $?
