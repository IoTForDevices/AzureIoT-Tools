#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

###############################################################################
# This script builds a X.509 verification certificate.
# It will used to validate the certificate ownership by signing a verification
# code with the private key that is associated with your X.509 CA certificate.
#
# Pre-requisites: You must have created and uploaded a root or intermediate
# certificate to your IoT Hub and you must have generated a verification code.
###############################################################################

show_help() {
    echo "Command"
    echo "  create-verification-cert: Create a new X.509 verification certificate that can be used to validate the uploaded X.509 Intermediate certificate."
    echo "      More information can be found in the IoT Hub documentation, see https://docs.microsoft.com/azure/iot-hub/iot-hub-x509ca-overview/"
    echo ""
    echo "Arguments"
    echo "  --root-folder -r        [Required] : Name of the folder where the certificates will be stored."
    echo "  --cert-name -c          [Required] : Name of the X.509 root certificate to be created." 
    echo "  --verification-code -v  [Required] : Verification code for authentication chain trust."
    echo "  --help -h                          : Shows this help message and exit."
    echo ""
    echo "NOTE: You must already have a X.509 Intermediate Certificate uploaded to an IoT Hub"
}

pwd_file=""
root_folder=""
verification_cert_name=""
chain_cert_name=""
cn_name=""

OPTS=`getopt -n 'parse-options' -o hr:c:v:p: --long help,root-folder:,cert-name:,verification-code:,password-file: -- "$@"`

eval set -- "$OPTS"

#extract options and their arguments into variables
while true ; do
    case "$1" in
        -h | --help )
            show_help
            exit 0
            ;;
        -r | --root-folder )
            root_folder="$2/ca"
            intermediate_folder="${root_folder}/intermediate"; shift 2 ;;
        -c | --cert-name )
            verification_cert_name="${2}-verify"
            chain_cert_name="${2}-chain"; shift 2 ;;
        -v | --verification-code )
            cn_name="/CN=${2}"; shift 2 ;;
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

if [[ -z "$root_folder" || -z "$verification_cert_name" || -z "$cn_name" ]]; then
    show_help
    exit 1
fi

if [ -z "$pwd" ]; then
    IFS= read -s -p Password: pwd
fi

cd ${root_folder}

# Create an verification key and make sure to keep it secure.
openssl genrsa \
    -aes256 \
    -passout pass:${pwd} \
    -out intermediate/private/${verification_cert_name}.key.pem 4096
chmod 400 intermediate/private/${verification_cert_name}.key.pem

# Use the previously created key to create a certificate signing request (CSR).
openssl req \
    -config intermediate/openssl.cnf \
    -key intermediate/private/${verification_cert_name}.key.pem \
    -subj ${cn_name} \
    -new -sha256 \
    -passin pass:${pwd} \
    -out intermediate/csr/${verification_cert_name}.csr.pem
chmod 444 intermediate/csr/${verification_cert_name}.csr.pem

# Use the root CA to sign the generated verification CSR.
openssl ca -batch \
    -config intermediate/openssl.cnf \
    -passin pass:${pwd} \
    -extensions "server_cert" \
    -days 30 -notext -md sha256 \
    -in intermediate/csr/${verification_cert_name}.csr.pem \
    -out intermediate/certs/${verification_cert_name}.cert.pem
chmod 444 intermediate/certs/${verification_cert_name}.cert.pem

# Verify the intermediate certificate
openssl x509 \
    -noout -text \
    -in intermediate/certs/${verification_cert_name}.cert.pem

echo ""
echo ""

openssl verify \
    -CAfile intermediate/certs/${chain_cert_name}.cert.pem \
    intermediate/certs/${verification_cert_name}.cert.pem

echo ""
echo "CA Verification Certificate Generated At:"
echo "-----------------------------------------"
echo "intermediate/certs/${verification_cert_name}.cert.pem"
echo ""