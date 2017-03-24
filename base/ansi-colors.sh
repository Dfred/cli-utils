#!/bin/bash

if test -z "$CLI_UTILS_COLORS"; then
  CLI_UTILS_COLORS=:

## COLORIZE AND FORMATTING COMMAND LINE.
## MacOS: YOU NEED iTerm AND ACTIVATE 256 COLOR MODE IN ORDER TO WORK,
##    http://kevin.colyar.net/wp-content/uploads/2011/01/Preferences.jpg
## Linux: YOU ARE ALREADY PROVIDED.
## Windows: IF YOU'RE SERIOUS, TRY YOUR CHANCE WITH CYGWIN.
readonly CDG=$'\x1B[0;30m'                ## COLOR DARK GREY  #TDL USE ARRAY TO SPARE GLOBAL SCOPE?
readonly CRD=$'\x1B[0;31m'                ## COLOR RED
readonly CGN=$'\x1B[0;32m'                ## COLOR GREEN
readonly CYW=$'\x1B[0;33m'                ## COLOR YELLOW
readonly CBE=$'\x1B[0;34m'                ## COLOR BLUE
readonly CMA=$'\x1B[0;35m'                ## COLOR MAGENTA
readonly CCN=$'\x1B[0;36m'                ## COLOR CYAN
readonly CGY=$'\x1B[0;37m'                ## COLOR LIGHT GREY
readonly CWE=$'\x1B[1;37m'                ## COLOR WHITE (ALSO BOLD)
#readonly CBK='\x1B[m'                     ## COLOR BLACK
readonly NORM=$'\033[m'                   ##
readonly LARG=$'\033[1m'                  ## BOLD

readonly CMPV="${CMA}${LARG}"             ## COMPUTED VALUE
readonly USRV="${CCN}${LARG}"             ## USER-PROVIDED VALUE

readonly P_CRIT="${CRD}"                  ## LEVEL: CRITICAL ERROR
readonly P_WARN="${CYW}"                  ## LEVEL: WARNING
readonly P_SUCC="${CGN}"                  ## LEVEL: SUCCESS
readonly P_QSTN="${CGY}"                  ## LEVEL: QUESTION
readonly P_CSMC="${CBE}"                  ## LEVEL: COSMETIC (OPTIONAL)

## COLORISED ECHO WITH SUPPORT FOR FORMATTING.
## EXAMPLES YOU SHOULD TRY:
# e_color ${CMA} "This sentence is in magenta"
# e_color ${NORM} "default," "${CCN}cyan,"  "default," "${CRD}red."
# e_color ${NORM} "default," "${CCN}cyan,not default,   ${CRD}red."
# e_color ${CBE} -n "Hi " "${CMPV}$(whoami)"; e_color ${CGN} " GO?"
# e_color ${CWE} -n "this 2-call version"; e_color ${CYW} " also works!"
function e_color ()
  ## $1   : ANY OF P_* COLORS               #XXX: E.G: "-N ${P_CRIT}"
  ## $2   : OPTIONS TO echo (OPTIONAL)
  ## $3-n : MESSAGE
{
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

## CLOSE CONDITIONAL INCLUSION
fi          #XXX if test -z "$CLI_UTILS_COLORS"
