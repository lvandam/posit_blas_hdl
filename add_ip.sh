#!/bin/sh
[ -z "$SNAP_ROOT" ] && echo "Environment variable SNAP_ROOT not defined" && exit 1;

mkdir -p ${SNAP_ROOT}/hardware/ip/managed_ip_project/managed_ip_project.srcs/sources_1/ip
find ip/ -maxdepth 1 ! -path ip/ -type d -exec ln -s ${SNAP_ROOT}/actions/${PWD##*/}/{} ${SNAP_ROOT}/hardware/ip/managed_ip_project/managed_ip_project.srcs/sources_1/{} ';'
