#!/bin/bash

##
## BASE FUNCTIONS FOR A COLORFUL INTERACTIVE CLI.
##

if test -z "${BASH_SOURCE[0]}"; then
  read -p '$BASH_SOURCE support required. Press Enter to continue.'
elif test -z "$CLI_UTILS_DEFINED"; then
  CLI_UTILS_DEFINED=:
  ## CAN DO OUR STUFF AND AS PEDANTIC AS TO STOP ON ERROR
  source $(dirname ${BASH_SOURCE[0]})/exit-codes.sh
  [[ "$0" != /bin/bash ]] && set -e       ## CATCH ERRORS IN YOUR OWN SCRIPTS

## ===============
## = FANCY STUFF =
## ===============

source $(dirname ${BASH_SOURCE[0]})/ansi-colors.sh
## COPY OR SET THE FOLLOWING FOR INCLUSION IN bot_* FUNCTIONS
# readonly BP="  "                          ## BOT PREFIX (INDENTATION)
# readonly BS="$CBE"                        ## BOT SKIN COLOR
# readonly B_AWAKE="$BS(${CGY}｡${CCN}◕$BS‿${CCN}◕${CGY}｡$BS)${NORM}"
# readonly B_HAPPY="$BS(${CGN}｡${CYW}^$BS‿${CYW}^${CGN}｡$BS)${NORM}"
# readonly B_UPSET="$BS(${CRD}｡${CYW}⊗$BS˳${CYW}⊗${CRD}｡$BS)${NORM}"
# readonly B_DYING="$BS(${CDG}｡${CYW}x$BS⁔${CYW}x${CDG}｡$BS)${NORM}"
# readonly B_WAIT1="$BS(${CGY}｡${CGN}◑$BS˳${CGN}◑${CGY}｡$BS)${NORM}"
# readonly B_WAIT2="$BS(${CWE}｡${CGN}◒$BS‿${CGN}◒${CWE}｡$BS)${NORM}"
# readonly B_WAIT3="$BS(${CGY}｡${CGN}◐$BS‿${CGN}◐${CGY}｡$BS)${NORM}"
# readonly B_WAIT4="$BS(${CBK}｡${CGN}◓$BS‿${CGN}◓${CBK}｡$BS)${NORM}"
# readonly B_EMBRS="$B_WAIT1"               ## EMBARRASSED (AKA PEBKAC)

##
## PROMPTED FUNCTIONS (SEE $BP)
##

## SCRIPT HAS SOMETHING INFORMATIVE TO SAY.
function bot_info ()
  ## $@ : SAME AS echo
{
  echo -ne "$BP$B_AWAKE "
  e_color ${P_CSMC} "$@"
}

## SCRIPT HAS SOMETHING HE'S HAPPY ABOUT.
function bot_success ()
  ## $@ : SAME AS echo (MESSAGE WILL BE PREFIXED)
{
  echo -ne "$BP$B_HAPPY "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  e_color ${P_SUCC} "$opts" "Good: $@"
}

## SCRIPT HAS SOMETHING YOU SHOULD PAY ATTENTION TO.
function bot_warn ()
  ## $@ : SAME AS echo (MESSAGE WILL BE PREFIXED)
{
  echo -ne "$BP$B_UPSET "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  e_color ${P_WARN} "$opts" "Hey! $@"
}

## SCRIPT HAS SOMETHING HE'S CHOCKING ABOUT AND WILL DIE.
function bot_fatal ()
  ## $1   : exit CODE
  ## $2-n : SAME AS echo (MESSAGE WILL BE PREFIXED)
{
  ecode=$1; shift
  echo; echo -ne "$BP$B_DYING "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  e_color ${P_CRIT} "$opts" "I require $@"
  exit $ecode
}

## SCRIPT HAS SOMETHING TO ASK AND WANT A VALID OR EMPTY ANSWER.
#XXX E.G: bot_choice "are you OK?" 2 yes no 'who knows!'
function bot_choice ()                    #XXX: FANCIER select ALTERNATIVE
  ## $1     : MESSAGE
  ## $2     : DEFAULT (AS INDEX IN $choices) IF USER PROVIDES AN EMPTY ANSWER
  ## $3-n   : CHOICES (WITH UNIQUE LEADING CHARACTER, E.G: "yes" "no" "abort")
  ## returns: 0, AND SETS $BOTASK_ANSWER TO THE ANSWER'S INDEX WITHIN $choices
{
  ## EASE OUR DEVS' LIFE
  [[ $2 =~ ^-?[0-9]+$ ]] || fatal_prog_error "'$2' IS NOT AN INTEGER";
  local max_i=$(expr $# - 2)
  [[ $2 -lt $max_i ]] || fatal_prog_error "'$2' >= MAX INDEX ($max_i)";

  local msg="$1" def_choice=$2; shift 2
  local choices=("$@")
  local prompt="$BP"
  #TDL CONSIDER A VERSION of bot_choice() USING $1 AS SET-BY-REFERENCE VARIABLE
  BOTASK_ANSWER="$def_choice"             #XXX: ACCESS TO USER'S CHOICE
  for c in "$@"; do
    if [[ "$c" == "${choices[$def_choice]}" ]]; then
      prompt="$prompt${LARG}[${c:0:1}]${c:1}${NORM} "
    else
      prompt="$prompt[${c:0:1}]${c:1} "
    fi
  done

  while true; do
    read -p $"$BP$B_AWAKE ${P_QSTN} $msg $prompt> " -r -N1 REPLY
    for (( i=0; i<=${#choices[@]}-1; i++ )); do
      test -z "$REPLY" && return 0
      c=${choices[$i]}
      if [[ "${REPLY:0:1}" == ${c:0:1} ]]; then
        read -p $'\n' -r -N1 -t0.001 || : #XXX: ENFORCE \n TO PRESERVE EYES
        BOTASK_ANSWER=$i && return 0      #XXX: set -e SO RETURN 0
      fi
    done
    echo -e "\r$BP$B_EMBRS" >&2           ## USER MISTYPED: EMBARRASSMENT
  done
}

## SCRIPT WAITS FOR AN EVALED EXPRESSION TO EXIT A NON-ZERO VALUE.
#XXX E.G: bot_waitWhile test -n \"'$(procname2p \$RE_PROC_httpd)'\"
function bot_waitWhile ()                 #TDL: ADD TIMEOUT?
  ## $1     : bash EXPRESSION
  ## returns: 0
{
  local s=0 out=""
#  set -ex                                #XXX: UNCOMMENT WHEN IT GETS TRICKY.
  while eval $@; do
    sleep 0.25s;
    echo -en "\r$BP$B_WAIT1 $s"s. ; out=1
    echo -en "\t waiting for ($@) to exit non-zero.\t"
    sleep 0.25s;
    echo -en "\r$BP$B_WAIT2 $s"s.
    sleep 0.25s;
    echo -en "\r$BP$B_WAIT3 $s"s.
    sleep 0.25s;
    echo -en "\r$BP$B_WAIT4 $s"s.
    s=$((s+1))
  done
  test -n "$out" && echo                  #XXX: while CAN BREAK DIRECTLY
  return 0
}

## SCRIPT USES N-th ARG IF SET OR ASKS FOR A VALUE
#XXX: E.G: ask_or_arg 0 '"are you OK? " 1 yes no' sure unsure; [[ $?==2 ]] && echo ""
function bot_argOrChoice ()
  ## $1     : N (*INDEX* IN LIST CONSISTING OF ARGUMENTS FROM $3)
  ## $2     : bot_choice COMMAND GIVEN TO eval; E.G: '"proceed? " 1 yes no'
  ## $3-n   : LIST OF ARGUMENTS TO BE INDEXED WITH $1; E.G: $@
  ## echoes : VALUE AT LIST'INDEX OR USER PROVIDED STRING
  ## returns: VALUE ORIGIN: 1 IF FROM ARGUMENTS, 2 IF FROM USER INPUT
{
  ## EASE OUR DEVS' LIFE
  [[ $1 =~ ^-?[0-9]+$ ]] || fatal_prog_error "'$1' IS NOT AN INTEGER";

  local i=$1; eval "local bc_args=($2)"; shift 2
  local list=("$@")

  if [[ -n "${list[$i]}" ]]; then
    echo "${list[$i]}"
    return 1
  else
    bot_choice "${bc_args[0]}" ${bc_args[@]:1}
    echo ${bc_args[$BOTASK_ANSWER+2]}
    return 2
  fi
}

fi
