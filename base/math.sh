#!/bin/bash

##
## SIMPLE MATH FUNCTIONS
##

## ENSURE GOOD SOURCING
if test -z "${BASH_SOURCE[0]}"; then
  read -p '$BASH_SOURCE support required. Press Enter to continue.'
elif test -z "$CLI_UTILS_DEFINED"; then
  CLI_UTILS_DEFINED=:
  ## CAN DO OUR STUFF AND AS PEDANTIC AS TO STOP ON ERROR
  source $(dirname ${BASH_SOURCE[0]})/base-exit_codes.sh
  [[ "$0" != /bin/bash ]] && set -e       ## CATCH ERRORS IN YOUR OWN SCRIPTS

## REMOVES DASHES TO ARGUMENT
## @return echo OF ABSOLUTE NUMBER
function math_abs ()
  ## $1: RELATIVE NUMBER
{
  echo ${1/#-/}
}

## CREATES A RANDOM STRING OF CONSISTING OF BASE64 CHARACTERS.
## @see ALSO rand_b64_big FOR LENTHS ~> 100 (FOR 100, 38 CHARS ARE WASTED)
## @return echo OF STRING OF $1 LENGTH
function rand_b64 ()
  ## $1: LENGTH OF STRING TO GENERATE
{
  test -z "$1" && return $EXIT_MISSING_ARGUMENT
  $( type -t head base64 > /dev/null ) || return $EXIT_UNUSABLE_SYS
  
  result=$(head -c $1 /dev/urandom | base64)
  echo ${result::$1}
}

## CREATES A RANDOM STRING OF CONSISTING OF BASE64 CHARACTERS. FOR LONG STRINGS.
## @return echo OF STRING OF $1 LENGTH
function rand_b64_big ()
  ## $1: LENGTH OF STRING TO GENERATE
{
  test -z "$1" && return $EXIT_MISSING_ARGUMENT
  $( type -t head base64 bc > /dev/null) || return $EXIT_UNUSABLE_SYS

  local chars=$(bc <<< "$1 * .740261")    # TESTED WITH 100MB LENGTH
  # bc IS POSIX BUT HAS NO CONSENSUS ON ROUNDING (scale=0 DOESN'T WORK)
  result=$(head -c ${chars%.*} /dev/urandom | base64)
  echo ${result::$1}
}

fi
