#!/bin/bash

# STOP ON ERROR
set -e                                    ## CATCH ERRORS IN YOUR OWN SCRIPTS

## ===============
## = FANCY STUFF =
## ===============

readonly EXIT_OK=0
## MAYBE LEAVE ROOM FOR LSB init SCRIPTS EXIT CODES
readonly EXIT_UNKNOWN=10
readonly EXIT_USER_ABORT=11
readonly EXIT_INVALID_ARGUMENT=12
## LEAVE [ 64 - 78 ] (SEE /usr/include/sysexits.h)
#readonly EXIT_

## ===============
## = FANCY STUFF =
## ===============

## COLORIZE AND FORMATTING COMMAND LINE.
## MacOS: YOU NEED iTerm AND ACTIVATE 256 COLOR MODE IN ORDER TO WORK,
##    http://kevin.colyar.net/wp-content/uploads/2011/01/Preferences.jpg
## Linux: YOU ARE ALREADY PROVIDED.
## Windows: IF YOU'RE SERIOUS, TRY YOUR CHANCE WITH CYGWIN.
readonly CDG='\x1B[0;30m'                 ## COLOR DARK GREY
readonly CRD='\x1B[0;31m'                 ## COLOR RED
readonly CGN='\x1B[0;32m'                 ## COLOR GREEN
readonly CYW='\x1B[0;33m'                 ## COLOR YELLOW
readonly CBE='\x1B[0;34m'                 ## COLOR BLUE
readonly CMA='\x1B[0;35m'                 ## COLOR MAGENTA
readonly CCN='\x1B[0;36m'                 ## COLOR CYAN
readonly CGY='\x1B[0;37m'                 ## COLOR LIGHT GREY
readonly CWE='\x1B[1;37m'                 ## COLOR WHITE (ALSO BOLD)
#readonly CBK='\x1B[m'                     ## COLOR BLACK
readonly NORM='\033[m'                    ##
readonly LARG='\033[1m'                   ## BOLD
readonly CMPV="${CMA}${LARG}"             ## COMPUTED VALUE
readonly USRV="${CCN}${LARG}"             ## USER-PROVIDED VALUE

readonly P_CRIT="${CRD}"                  ## LEVEL: CRITICAL ERROR
readonly P_WARN="${CYW}"                  ## LEVEL: WARNING
readonly P_SUCC="${CGN}"                  ## LEVEL: SUCCESS
readonly P_QSTN="${CGY}"                  ## LEVEL: QUESTION
readonly P_CSMC="${CBE}"                  ## LEVEL: COSMETIC (OPTIONAL)

## ======================
## = HELPING FUNCTIONS  =
## ======================

function fatal_prog_error () {
  echo -e "${CRD}${LARG}SCRIPT ERROR${NORM}${CRD} [$0:${BASH_LINENO[1]}] CALL"\
    TO ${FUNCNAME[1]}:${NORM} $1
  exit 127
}

## INVOKE SUDO/SU IF NEEDED
function run_as () {
  ## $1: USER NAME
  if ! getent passwd $1 >/dev/null 2>&1; then
    fatal_prog_error "USER '$1' DOES NOT EXIST"
  fi
  if [[ $(whoami) != "$1" ]]; then
    local prefix="sudo -u $1"
  fi
  shift
  $prefix "$@"
}

## PROCESS_NAME TO USER_NAME PID PROCESS_NAME.
function procname2Upca () {
  ## $1: PROCESS NAME - REGEXP ALLOWED
  ps ax -o '%U %p %a' | grep -E "$1"                  | grep -v grep |sort
}

## PROCESS_NAME TO USER_NAME.
function procname2U () {
  ## $1: PROCESS NAME - REGEXP ALLOWED
  ps ax -o '%U %c'    | grep -E "$1" | cut -f1 -d' '  | grep -v grep |sort
}

## PROCESS_NAME TO PID.
function procname2p () {
  ## $1: PROCESS NAME - REGEXP ALLOWED
  ps ax -o '%p %U'    | grep -E "$1" | cut -f1 -d' '  | grep -v grep |sort
}

## GENERIC COLORISED PRINT WITH SUPPORT FOR FORMATTING.
function p_color () {
  ## $1   : ANY OF P_* COLORS               #XXX: E.G: "-N ${P_CRIT}"
  ## $2   : OPTIONS TO echo (OPTIONAL)
  ## $3-n : MESSAGE
  local color="$1"; shift
  local opts=""
  if [[ ${1:0:1} == "-" ]]; then
    opts="$1"; shift
  fi
  for str in "$@"; do
    echo -ne $opts "$color$str"
  done
  echo -e $opts ${NORM}
}
## EXAMPLES YOU SHOULD TRY:
# p_color ${CMA} "This sentence is in magenta"
# p_color ${NORM} "default," "${CCN}cyan,"  "default," "${CRD}red."
# p_color ${NORM} "default," "${CCN}cyan,not default,   ${CRD}red."
# p_color ${CBE} -n "Hi " "${CMPV}$(whoami)"; p_color ${CGN} " GO?"
# p_color ${CWE} -n "this 2-call version"; p_color ${CYW} " also works!"

## SCRIPT HAS SOMETHING INFORMATIVE TO SAY.
function bot_info () {
  ## $@ : same as echo
  echo -ne "$BP$B_AWAKE "
  p_color ${P_CSMC} "$@"
}

## SCRIPT HAS SOMETHING HE'S HAPPY ABOUT.
function bot_success () {
  ## $@ : SAME AS echo (MESSAGE WILL BE PREFIXED)
  echo -ne "$BP$B_HAPPY "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  p_color ${P_SUCC} "$opts" "Good: $@"
}

## SCRIPT HAS SOMETHING YOU SHOULD PAY ATTENTION TO.
function bot_warn () {
  ## $@ : SAME AS echo (MESSAGE WILL BE PREFIXED)
  echo -ne "$BP$B_UPSET "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  p_color ${P_WARN} "$opts" "Hey! $@"
}

## SCRIPT HAS SOMETHING HE'S CHOCKING ABOUT AND WILL DIE.
function bot_fatal () {
  ## $1   : exit CODE
  ## $2-n : SAME AS echo (MESSAGE WILL BE PREFIXED)
  ecode=$1; shift
  echo; echo -ne "$BP$B_DYING "
  [[ ${1:0:1} == '-' ]] && local opts="$1" && shift
  p_color ${P_CRIT} "$opts" "I require $@"
  exit $ecode
}

## SCRIPT HAS SOMETHING TO ASK AND WANT A VALID OR EMPTY ANSWER.
function bot_choice () {                  #XXX: FANCIER select ALTERNATIVE
  ## $1     : MESSAGE
  ## $2     : DEFAULT (AS INDEX IN $choices) IF USER PROVIDES AN EMPTY ANSWER
  ## $3-n   : CHOICES (WITH UNIQUE LEADING CHARACTER, E.G: "yes" "no" "abort")
  ## returns: 0, AND SETS $BOTASK_ANSWER TO THE ANSWER'S INDEX WITHIN $choices

  ## EASE OUR DEVS' LIFE
  [[ $2 =~ ^-?[0-9]+$ ]] || fatal_prog_error "'$2' IS NOT AN INTEGER";

  local msg="$1" def_choice=$2; shift 2
  local choices=($@)
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
    echo -ne "$BP$B_AWAKE "
    p_color ${P_QSTN} -n "$msg"
    echo -ne "$prompt> "
    read -N 1 ans
    for (( i=0; i<=${#choices[@]}-1; i++ )); do
      test -z $ans && return 0            #TDL: PRESSING SPACE (RETURN OK)
      c=${choices[$i]}
      if [[ "$ans" == ${c:0:1} ]]; then
        echo
        BOTASK_ANSWER=$i && return 0      #XXX: set -e SO RETURN 0
      fi
    done
    echo -e "\r$BP$B_EMBRS"               ## USER MISTYPED: EMBARRASSMENT
  done
}

## SCRIPT WAITS FOR AN EVALED EXPRESSION TO EXIT A NON-ZERO VALUE.
#XXX: EXAMPLE CALL: bot_waitWhile test -n \"'$(procname2p \$RE_PROC_httpd)'\"
function bot_waitWhile () {               #TDL: ADD TIMEOUT?
  ## $1     : bash EXPRESSION
  ## returns: 0
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

## SCRIPT USES N-th ARG OR ASKS FOR A VALUE
#XXX: EXAMPLE CALL: ask_or_arg 2 '"are you OK? " 1 yes no' sure unsure maybe
function bot_argOrChoice () {
  ## $1     : N (*INDEX* IN LIST CONSISTING OF ARGUMENTS FROM $3)
  ## $2     : bot_choice COMMAND GIVEN TO eval; E.G: '"proceed? " 1 yes no'
  ## $3-n   : LIST OF ARGUMENTS TO BE INDEXED WITH $1; E.G: $@
  ## return : VALUE AT LIST'INDEX OR USER PROVIDED STRING
  local i=$1; eval "local bc_args=($2)"; shift 2
  local list=($@)
  if [[ -n "${list[$i]}" ]]; then echo "${list[$i]}";
  else bot_choice "${bc_args[0]}" ${bc_args[@]:1}
    echo ${bc_args[$BOTASK_ANSWER+2]}
  fi
}
