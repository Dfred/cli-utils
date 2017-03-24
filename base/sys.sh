#!/bin/bash

## ======================
## = IMPROVE VERBOSITY  =
## ======================

## SHOW AND DO. USEFUL TO INFORM AND/OR DEBUG.
function echo_run ()
  ## $@: COMMAND TO RUN
{
  echo "# $@"
  $@
}

## exit WITH $EXIT_FATAL_ERROR AFTER DISPLAYING SOME CONTEXT (HELP DEBUGGING)
function fatal_prog_error ()
  ## $1: MESSAGE DISPLAYED AFTER CONTEXT
{
  echo -e "${CRD}${LARG}SCRIPT ERROR${NORM}${CRD} [$0:${BASH_LINENO[1]}] CALL"\
    TO ${FUNCNAME[1]}:${NORM} $1
  exit $EXIT_FATAL_ERROR
}

## =====================
## = FETCH INFOS IN OS =
## =====================

## INVOKE SUDO/SU IF NEEDED
function run_as ()
  ## $1: USER NAME
{
  if ! getent passwd $1 >/dev/null 2>&1; then
    fatal_prog_error "USER '$1' DOES NOT EXIST"
  fi
  if [[ $(whoami) != "$1" ]]; then
    local prefix="sudo -u $1"
  fi
  shift
  $prefix "$@"
}

## CHECK FOR THE PRESENCE OF BINARIES, POTENTIALLY BAILING OUT
## AND SET VARIABLES (NAMED AS THE BINARY) TO THEIR FULLPATH.
function test_bin ()
  ## $1: IF 1, CALL p_fatal ON MISSING; IGNORE OTHERWISE
  ## $2-n: LIST OF BINARY NAMES TO BE FOUND
{
  local bail=$1; shift
  for bin in $@; do
    path=$(type -p $bin 2>/dev/null) && declare global $bin="$path" ||
      {
        test $bail && p_fatal $EXIT_UNUSABLE_SYS "$bin missing." ||
        continue
      }
    test -x "$path" || p_fatal $EXIT_UNUSABLE_SYS "$bin lacks executable flags."
  done
}

## PROCESS_NAME TO USER_NAME PID PROCESS_NAME.
function procname2Upca ()
  ## $1: PROCESS NAME - REGEXP ALLOWED
{
  ps ax -o '%U %p %a' | grep -E "$1"                  | grep -v grep |sort
}

## PROCESS_NAME TO USER_NAME.
function procname2U ()
  ## $1: PROCESS NAME - REGEXP ALLOWED
{
  ps ax -o '%U %c'    | grep -E "$1" | cut -f1 -d' '  | grep -v grep |sort
}

## PROCESS_NAME TO PID.
function procname2p ()
  ## $1: PROCESS NAME - REGEXP ALLOWED
{
  ps ax -o '%p %U'    | grep -E "$1" | cut -f1 -d' '  | grep -v grep |sort
}
