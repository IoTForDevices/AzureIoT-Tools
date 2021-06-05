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
    echo "  create-filesystem: Create a new directory tree to hold different X.509 certificates that can be used to authenticate devices connecting to an IoT Hub or an IoT Central application."
    echo ""
    echo "Arguments"
    echo "  --root-folder -r    [Required] : Name of the folder where the certificates will be stored."
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
ca_root_folder="${root_folder}/ca"
intermediate_folder="${ca_root_folder}/intermediate"

rm -r -f ${root_folder}

# Create the root CA file structure
mkdir ${root_folder}
mkdir ${ca_root_folder}

mkdir ${ca_root_folder}/crl
mkdir ${ca_root_folder}/private
chmod 700 ${ca_root_folder}/private
mkdir ${ca_root_folder}/certs
mkdir ${ca_root_folder}/newcerts

cp ${script_folder}/openssl.cnf ${ca_root_folder}

touch ${ca_root_folder}/index.txt
touch ${ca_root_folder}/index.txt.attr
echo 1000 > ${ca_root_folder}/serial

# Create the intermediate CA file structure
mkdir ${intermediate_folder}

mkdir ${intermediate_folder}/crl
mkdir ${intermediate_folder}/csr
mkdir ${intermediate_folder}/private
chmod 700 ${intermediate_folder}/private
mkdir ${intermediate_folder}/certs
mkdir ${intermediate_folder}/newcerts

cp ${script_folder}/openssl_intermediate.cnf ${intermediate_folder}/openssl.cnf

touch ${intermediate_folder}/index.txt
touch ${intermediate_folder}/index.txt.attr
echo 1000 > ${intermediate_folder}/serial
echo 1000 > ${intermediate_folder}/crlnumber

echo "script-folder = " $script_folder
echo "root-folder = " $root_folder
echo "ca_root_folder = " $ca_root_folder
echo "intermediate_folder = " $intermediate_folder
