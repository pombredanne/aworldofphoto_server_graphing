#!/bin/sh

# Setup an EC2 instance with puppet


image=ami-a7f539ce   # 32-bit Ubuntu 11.10
username=ubuntu      # as required bye the ami
ec2_type=m1.small
security_groups=default:photoworld-graphing

# define options
. ./shflags
FLAGS_HELP="USAGE: $0 [flags] aws_keyname aws_keyfile"

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
[ $# -gt 1 ] || die 'two arguments required'
aws_keyname=$1
aws_keyfile=$2


puppet node_aws bootstrap --image $image --keyname "$aws_keyname" --keyfile "$aws_keyfile" -l "$username" --type "$ec2_type" --security-group "$security_groups"
