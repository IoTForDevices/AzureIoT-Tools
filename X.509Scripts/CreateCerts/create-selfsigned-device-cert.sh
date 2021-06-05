#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

###########################################################################################
# This script builds a X.509 device certificate.
# It will used to validate the certificate ownership by signing a verification
# code with the private key that is associated with your intermediate X.509 CA certificate.
#
# Pre-requisites: You must have created and uploaded an intermediate
# certificate to your IoT Hub and you must have generated a verification code.
###########################################################################################

show_help() {
    echo "Command"
    echo "  create-selfsigned-device-cert: Create a new self-signed X.509 device certificate."
    echo ""
    echo "Arguments"
    echo "  --root-folder -r        [Required] : Name of the folder where the certificate will be stored."
    echo "  --registration-id -i    [Required] : Name with which the device appears in your IoTC solution."
    echo "  --help -h                          : Shows this help message and exit."
    echo ""
}

root_folder=""
device_cert_name=""
cn_name=""

OPTS=`getopt -n 'parse-options' -o hr:i: --long help,root-folder:,registration-id: -- "$@"`

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
        -i | --registration-id )
            device_cert_name="$2-device"
            cn_name="/CN=$2"; shift 2 ;;
        \? )
            echo "Invalid Option"
            exit 0
            ;;
        --) shift; break;;
        *) break;;
    esac
done

if [[ -z "$root_folder" || -z "$device_cert_name" ]]; then
    show_help
    exit 1
fi

cd ${root_folder}

# write the CN in the cnf file
sed -i "34s\\commonName_placeholder\\${device_cert_name}\\" openssl_selfsigned_device.cnf

# Create an verification key and make sure to keep it secure.
echo ""
echo "Generated a device creation key."
echo ""
openssl genrsa -out private/${device_cert_name}.key.pem 2048
chmod 400 private/${device_cert_name}.key.pem

# Use the above generated key to create a certificate signing request (CSR).
echo ""
echo "Use the generated key to create a certificate signing request (CSR)"
echo ""
openssl req \
    -new -key private/${device_cert_name}.key.pem \
    -config openssl_selfsigned_device.cnf \
    -out csr/${device_cert_name}.csr
chmod 444 csr/${device_cert_name}.csr

# Use the private key and verification CSR to create a x509 certificate.
echo ""
echo "Use the private key and verification CSR to create a x509 certificate"
echo ""
openssl x509 -req \
    -days 1500 \
    -in csr/${device_cert_name}.csr \
    -signkey private/${device_cert_name}.key.pem \
    -out ${device_cert_name}.cert.pem
chmod 444 ${device_cert_name}.cert.pem

# Use the x509 certificate to create a device certificate.
echo ""
echo "Use the x509 certificate to create a device certificate"
echo ""
openssl x509 \
    -inform PEM -outform DER \
    -in ${device_cert_name}.cert.pem \
    -out ${device_cert_name}_cert_formatted.der

# Create a private key for the device as well
echo ""
echo "Create a device private key"
echo ""
openssl rsa \
    -inform PEM -outform DER \
    -in private/${device_cert_name}.key.pem \
    -out ${device_cert_name}_privatekey_formatted.der

# Store the content of the certificate and the key in hex format into a c header file.
xxd -i ${device_cert_name}_cert_formatted.der > cert.c
xxd -i ${device_cert_name}_privatekey_formatted.der >> cert.c

echo "Self-signed certificate and private key can be found in cert.c"
echo "--------------------------------------------------------------"
