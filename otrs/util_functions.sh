#!/bin/bash

# trap keyboard interrupt (control-c)
trap 'control_c $MOUNTPOINT' SIGINT

control_c()
# run if user hits control-c
{

  echo -e "\n*** Ouch! Cleaning up ***\n"
  exit $?
}

print_info()
{
  echo -e "\e[42m[INFO]\e[0m $1"
}

print_error()
{
    echo -e "\e[101m[ERROR]\e[0m $1"
}

print_warning()
{
    echo -e "\e[43m[WARNING]\e[0m $1"
}
