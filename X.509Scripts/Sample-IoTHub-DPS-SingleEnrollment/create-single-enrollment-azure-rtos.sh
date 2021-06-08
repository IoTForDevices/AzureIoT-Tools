#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

#######################################################################################
# This script creates a self-signed X.509 certificate and private key that
# can be used as a device certificate for IoTC single X.509 individual enrollments.
# 
# The certificate and key created are stored in a c source file to be used in a
# Azure RTOS powered device that uses the embedded C SDK for Azure IoT.
#######################################################################################

show_help() {
    echo "Command"
    echo "  create-single-enrollment-azure-rtos: Create a new self-signed X.509 certificate to authenticate devices (DPS Single Enrollment for Azure RTOS powered devices)."
    echo ""
    echo "Arguments"
    echo "  --root-folder -r        [Required] : Name of the folder where the certificates will be stored."
    echo "  --registration-id -i    [Required] : Name with which the device appears in your IoTC solution."
    echo "  --help -h                          : Shows this help message and exit."
}

root_folder=""
registration_id=""

OPTS=`getopt -n 'parse-options' -o hi:r: --long help,registration-id:,root-folder: -- "$@"`

eval set -- "$OPTS"

#extract options and their arguments into variables
while true ; do
    case "$1" in
        -h | --help )
            show_help
            exit 0
            ;;
        -i | --registration-id )
            registration_id="$2"; shift 2 ;;
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

if [[ -z "$registration_id" || -z "$root_folder" ]]; then
    show_help
    exit 1
fi

../Sample-IoTC-SingleEnrollment/create-single-enrollment-azure-rtos.sh -r ${root_folder} -i ${registration_id}
