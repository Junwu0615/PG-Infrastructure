#!/usr/bin/env bash

set -e

ACTION=$1

if [ -z "$ACTION" ]; then
  echo "Usage: ./vm-power.sh [start|stop|reboot|status]"
  exit 1
fi

VMS=$(sudo virsh list --all --name | grep k3s)

if [ -z "$VMS" ]; then
  echo "No k3s VMs found."
  exit 1
fi

for vm in $VMS; do
  echo "===> $ACTION : $vm"

  case $ACTION in
    start)
      sudo virsh start "$vm" || true
      ;;

    stop)
      sudo virsh shutdown "$vm" || true
      ;;

    reboot)
      sudo virsh reboot "$vm" || true
      ;;

    force-stop)
      sudo virsh destroy "$vm" || true
      ;;

    status)
      sudo virsh domstate "$vm"
      ;;

    *)
      echo "Invalid action: $ACTION"
      exit 1
      ;;
  esac
done