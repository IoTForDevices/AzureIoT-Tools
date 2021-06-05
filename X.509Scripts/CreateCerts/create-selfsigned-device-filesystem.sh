#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

###############################################################################
# This script builds a directory structure to be used to setup an
# X.509 certificate chain for CA deployment.
#
# These certs are mainly used for testing and development.
###############################################################################

# if [ $# -ne 1 ]; then
#    echo "Usage: create-filesystem <root-folder>"
#    exit 1
# else
#    echo $1
# fi

##############################
show_help() {
    echo "Command"
    echo "  create-selfsigned-device-filesystem: Create a directory tree to hold a self-signed X.509 device certificate that can be used to authenticate devices connecting to an IoT Central application"
    echo "                                       or to connect to an IoT Hub through DPS with a single enrollment."
    echo ""
    echo "Arguments"
    echo "  --root-folder -r    [Required] : Name of the folder where the certificate will be stored."
    echo "  --help -h                      : Shows this help message and exit."
}

root_folder=""

OPTS=`getopt -n 'parse-options' -o hr: --long help,root-folder: -- "$@"`

eval set -- "$OPTS"

#extract options and their arguments into variables
while true ; do
    case "$1" in
        -h | --help )
            show_help
            exit 0
            ;;
        -r | --root-folder )
            root_folder="$2"; shift 2 ;;
        \? )
            echo "Invalid Option"
            exit 0
            ;;
        --) shift; break;;
        *) break;;
    esac
done

if [[ -z "$root_folder" ]]; then
    show_help
    exit 1
fi

script_folder=`dirname "$0"`

rm -r -f ${root_folder}

# Create the root folder and file structure
mkdir ${root_folder}

mkdir ${root_folder}/csr
mkdir ${root_folder}/private
chmod 700 ${root_folder}/private

cp ${script_folder}/openssl_selfsigned_device.cnf ${root_folder}

echo "script-folder = " $script_folder
echo "root-folder = " $root_folder
