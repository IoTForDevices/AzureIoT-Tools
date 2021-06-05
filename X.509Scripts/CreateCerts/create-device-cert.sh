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
    echo "  create-device-cert: Create a new X.509 device certificate that can be used to authenticate devices connecting to an IoT Hub."
    echo "      More information can be found in the IoT Hub documentation, see https://docs.microsoft.com/azure/iot-hub/iot-hub-x509ca-overview/"
    echo ""
    echo "Arguments"
    echo "  --root-folder -r    [Required] : Name of the folder where the certificates will be stored."
    echo "  --cert-name -c      [Required] : Name of the X.509 root certificate to be created." 
    echo "  --device-id -d      [Required] : Name of the device identity for the new device."
    echo "  --help -h                      : Shows this help message and exit."
    echo ""
    echo "NOTE: You must already have a X.509 root certificate with the same name to be able to sign this X.509 intermediate certificate"
    echo "      to be able to create a chain of trust."
}

pwd_file=""
root_folder=""
device_cert_name=""
chain_cert_name=""
cn_name=""

OPTS=`getopt -n 'parse-options' -o hr:c:d: --long help,root-folder:,cert-name:,device-id: -- "$@"`

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
            chain_cert_name="$2-chain"; shift 2 ;;
        -d | --device-id )
            device_cert_name="$2-device"
            cn_name="/CN=$2"; shift 2 ;;
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

if [[ -z "$root_folder" || -z "$chain_cert_name" || -z "$device_cert_name" ]]; then
    show_help
    exit 1
fi

if [ -z "$pwd" ]; then
    IFS= read -s -p Password: pwd
fi

cd ${root_folder}

# Create an verification key and make sure to keep it secure.
echo ""
echo "Generated a device creation key."
echo ""
openssl genrsa \
    -aes256 \
    -passout pass:${pwd} \
    -out intermediate/private/${device_cert_name}.key.pem 4096
chmod 400 intermediate/private/${device_cert_name}.key.pem

# Use the above generated key to create a certificate signing request (CSR).
echo ""
echo "Use the generated key to create a certificate signing request (CSR)"
echo ""
openssl req \
    -config intermediate/openssl.cnf \
    -key intermediate/private/${device_cert_name}.key.pem \
    -subj ${cn_name} \
    -new -sha256 \
    -passin pass:${pwd} \
    -out intermediate/csr/${device_cert_name}.csr.pem
chmod 444 intermediate/csr/${device_cert_name}.csr.pem

# Use the Intermediate CA to sign the generated verification CSR.
echo ""
echo "Use the Intermediate CA to sign the generated verification CSR"
echo ""
openssl ca -batch \
    -config intermediate/openssl.cnf \
    -passin pass:${pwd} \
    -extensions "server_cert" \
    -days 1500 -notext -md sha256 \
    -in intermediate/csr/${device_cert_name}.csr.pem \
    -out intermediate/certs/${device_cert_name}.cert.pem
chmod 444 intermediate/certs/${device_cert_name}.cert.pem

# Verify the intermediate certificate
echo ""
echo "Use the Intermediate CA to sign the generated verification CSR"
echo ""
openssl x509 \
    -noout -text \
    -in intermediate/certs/${device_cert_name}.cert.pem

echo ""
echo ""

openssl verify \
    -CAfile intermediate/certs/${chain_cert_name}.cert.pem \
    intermediate/certs/${device_cert_name}.cert.pem

echo ""
echo "CA Verification Certificate Generated At:"
echo "-----------------------------------------"
echo "intermediate/certs/${device_cert_name}.cert.pem"
echo ""


openssl pkcs12 -in intermediate/certs/${device_cert_name}.cert.pem \
        -inkey intermediate/private/${device_cert_name}.key.pem \
        -passin pass:${pwd} \
        -password pass:${pwd} \
        -export -out intermediate/certs/${device_cert_name}.cert.pfx

echo "${cert_type_diagnostic} PFX Certificate Generated At:"
echo "--------------------------------------------"
echo "    ${certificate_dir}/certs/${device_prefix}.cert.pfx"
