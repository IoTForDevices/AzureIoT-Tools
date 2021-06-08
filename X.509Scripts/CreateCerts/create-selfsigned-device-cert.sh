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

# Script variables that are used for the openssl subj
# Modify these values to match your device
my_country="NL"
my_state="ZH"
my_city="Alphen aan den Rijn"
my_organization="IoTForDevices"

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
device_name=""

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
            device_name="$2"; shift 2 ;;
        \? )
            echo "Invalid Option"
            exit 0
            ;;
        --) shift; break;;
        *) break;;
    esac
done

if [[ -z "$root_folder" || -z "$device_name" ]]; then
    show_help
    exit 1
fi

# Create the root folder (optionally delete an existing root-folder)
rm -r -f ${root_folder}
mkdir ${root_folder}
cd ${root_folder}

# Create an verification key and make sure to keep it secure.
echo ""
echo "Generated a primary device creation key."
echo ""
openssl genpkey -out ${device_name}_1.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
chmod 400 ${device_name}_1.key
echo ""
echo "Generated a secundary device creation key."
echo ""
openssl genpkey -out ${device_name}_2.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
chmod 400 ${device_name}_2.key

# Use the generated keys to create certificate signing requests (CSR).
echo ""
echo "Use the generated key to create a certificate signing request (CSR)"
echo ""
subj_str="/C=${my_country}/ST=${my_state}/L=${my_city}/O=${my_organization}/CN=${device_name}"

touch ~/.rnd
openssl req -new -key ${device_name}_1.key -subj "${subj_str}"  -out ${device_name}_1.csr
chmod 444 ${device_name}_1.csr
openssl req -new -key ${device_name}_2.key -subj "${subj_str}" -out ${device_name}_2.csr
chmod 444 ${device_name}_2.csr

# Use the private key and verification CSR to create a x509 certificate.
echo ""
echo "Use the private key and verification CSR to create a x509 certificate"
echo ""
openssl x509 -req -days 365 -in ${device_name}_1.csr -signkey ${device_name}_1.key -out ${device_name}_1.cert.pem
chmod 444 ${device_name}_1.cert.pem
openssl x509 -req -days 365 -in ${device_name}_2.csr -signkey ${device_name}_2.key -out ${device_name}_2.cert.pem
chmod 444 ${device_name}_2.cert.pem

# Show fingerprints for both certificates (needed for direct connections to IoTHub with self-signed devices)
openssl x509 -in ${device_name}_1.cert.pem -noout -fingerprint
openssl x509 -in ${device_name}_2.cert.pem -noout -fingerprint

# Use the x509 certificate to create a device certificate.
echo ""
echo "Use the x509 certificate to create a device certificate"
echo ""
openssl x509 -inform PEM -outform DER -in ${device_name}_1.cert.pem -out ${device_name}.der

# Create a private key for the device as well
echo ""
echo "Create a device private key"
echo ""
openssl rsa -inform PEM -outform DER -in ${device_name}_1.key -out ${device_name}_key.der

# Store the content of the certificate and the key in hex format into a c header file.
xxd -i ${device_name}.der > cert.c
xxd -i ${device_name}_key.der >> cert.c

echo "Self-signed certificate and private key can be found in cert.c"
echo "--------------------------------------------------------------"
