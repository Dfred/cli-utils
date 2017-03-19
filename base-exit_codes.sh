#!/bin/bash

readonly EXIT_OK=0
## MAYBE LEAVE ROOM FOR LSB init SCRIPTS EXIT CODES
readonly EXIT_UNKNOWN=10
readonly EXIT_USER_ABORT=11
readonly EXIT_FATAL_ERROR=12
readonly EXIT_UNUSABLE_SYS=13
readonly EXIT_NOT_IMPLEMENTED=14
readonly EXIT_INVALID_ARGUMENT=15         #XXX ALSO WHEN PEBKAC
## LEAVE [ 64 - 78 ] (SEE /usr/include/sysexits.h)
#readonly EXIT_
