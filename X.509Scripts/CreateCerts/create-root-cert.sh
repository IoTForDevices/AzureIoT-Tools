#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

###############################################################################
# This script builds a new X.509 root certificate.
# It will used as the root of trust for a chain of security certificates. 
#
# These certs are mainly used for testing and development.
#
# Pre-requisites: Run the create-filesystem script first.
###############################################################################

show_help() {
    echo "Command"
    echo "  create-root-cert: Create a new X.509 root certificate that can be used to authenticate devices connecting to an IoT Hub."
    echo "      More information can be found in the IoT Hub documentation, see https://docs.microsoft.com/azure/iot-hub/iot-hub-x509ca-overview/"
    echo ""
    echo "Arguments"
    echo "  --root-folder -r    [Required] : Name of the folder where the certificates will be stored."
    echo "  --cert-name -c      [Required] : Name of the X.509 root certificate to be created." 
    echo "  --help -h                      : Shows this help message and exit."
}

pwd_file=""
root_folder=""
root_cert_name=""

OPTS=`getopt -n 'parse-options' -o hr:c:p: --long help,root-folder:,cert-name:,password-file: -- "$@"`

eval set -- "$OPTS"

#extract options and their arguments into variables
while true ; do
    case "$1" in
        -h | --help )
            show_help
            exit 0
            ;;
        -r | --root-folder )
            root_folder="$2/ca"; shift 2 ;;
        -c | --cert-name )
            root_cert_name="$2-root"; shift 2 ;;
        -p | --password-file )
            pwd=`cat "$2"`; shift 2 ;; 
        \? )
            echo "Invalid Option"
            exit 0
            ;;
        --) shift; break;;
        *) break;;
    esac
done

if [[ -z "$root_folder" || -z "$root_cert_name" ]]; then
    show_help
    exit 1
fi

if [ -z "$pwd" ]; then
    IFS= read -s -p Password: pwd
fi

cd ${root_folder}

# write the root directory and the certificate name in the cnf file
sed -i "8s\\dir_place_holder\\${root_folder}\\" openssl.cnf
sed -i "17s\\root_key_placeholder\\${root_cert_name}.key.pem\\" openssl.cnf
sed -i "18s\\root_cert_placeholder\\${root_cert_name}.cert.pem\\" openssl.cnf
sed -i "22s\\root_crl_placeholder\\${root_cert_name}.crl.pem\\" openssl.cnf

# Create a root key and make sure to keep it secure.
openssl genrsa \
    -aes256 \
    -passout pass:${pwd} \
    -out private/${root_cert_name}.key.pem \
    4096
chmod 400 private/${root_cert_name}.key.pem

# Use the previously created root key to create a root certificate.
openssl req -batch \
    -config openssl.cnf \
    -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -passin pass:${pwd} \
    -key private/${root_cert_name}.key.pem \
    -out certs/${root_cert_name}.cert.pem
chmod 444 certs/${root_cert_name}.cert.pem

# Verify the root certificate
openssl x509 -noout -text -in certs/${root_cert_name}.cert.pem

echo ""
echo "CA Root Certificate Generated At:"
echo "---------------------------------"
echo "${root_folder}/certs/${root_cert_name}.cert.pem"
echo ""
