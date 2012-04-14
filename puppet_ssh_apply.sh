#!/bin/bash

# Apply this puppet configuration on the given host without using a master,
# but by deploying the files via rsync and then running apply remotely.


folder=puppet


# define options
. ./shflags
DEFINE_string 'key' '' 'ssh keyfile to use' 'k'
FLAGS_HELP="USAGE: $0 [flags] user@host"

die()
{
  [ $# -gt 0 ] && echo "error: $@" >&2
  flags_help
  exit 1
}

# parse the command-line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# check for host
[ $# -gt 0 ] || die 'host missing'
host=$1


RSYNC_COMMAND="rsync -rv"
if [ "${FLAGS_key}"  != "" ]; then
  RSYNC_COMMAND="$RSYNC_COMMAND -e \"ssh -i ${FLAGS_key}\""
fi
RSYNC_COMMAND="$RSYNC_COMMAND $folder $host:/tmp/"


SSH_COMMAND="ssh"
if [ "${FLAGS_key}"  != "" ]; then
  SSH_COMMAND="$SSH_COMMAND -i ${FLAGS_key}"
fi
SSH_COMMAND="$SSH_COMMAND $host sudo puppet apply --debug --modulepath /tmp/puppet /tmp/puppet/test.pp"

$RSYNC_COMMAND && $SSH_COMMAND

