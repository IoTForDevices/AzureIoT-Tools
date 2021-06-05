#!/bin/bash

## Copyright (c) IoTForDevices. All rights reserved.
## Licensed under the MIT license. See LICENSE file in the project root for full license information.

###############################################################################
# This script builds a new X.509 intermediate certificate.
# It will used to sign certificates on behalf of the root CA.
#
# These certs are mainly used for testing and development.
#
# Pre-requisites: Run the create-root-cert script first.
###############################################################################

show_help() {
    echo "Command"
    echo "  create-intermediate-cert: Create a new X.509 intermediate certificate that can be used to authenticate devices connecting to an IoT Hub."
    echo "      More information can be found in the IoT Hub documentation, see https://docs.microsoft.com/azure/iot-hub/iot-hub-x509ca-overview/"
    echo ""
    echo "Arguments"
    echo "  --root-folder -r    [Required] : Name of the folder where the certificates will be stored."
    echo "  --cert-name -c      [Required] : Name of the X.509 root certificate to be created." 
    echo "  --help -h                      : Shows this help message and exit."
    echo ""
    echo "NOTE: You must already have a X.509 root certificate with the same name to be able to sign this X.509 intermediate certificate"
    echo "      to be able to create a chain of trust."
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
            root_folder="$2/ca"
            intermediate_folder="${root_folder}/intermediate"; shift 2 ;;
        -c | --cert-name )
            root_cert_name="$2-root"
            intermediate_cert_name="$2-intermediate"
            chain_cert_name="$2-chain"; shift 2 ;;
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
sed -i "8s\\dir_place_holder\\${intermediate_folder}\\" intermediate/openssl.cnf
sed -i "17s\\intermediate_key_placeholder\\${intermediate_cert_name}.key.pem\\" intermediate/openssl.cnf
sed -i "18s\\intermediate_cert_placeholder\\${intermediate_cert_name}.cert.pem\\" intermediate/openssl.cnf
sed -i "22s\\intermediate_crl_placeholder\\${intermediate_cert_name}.crl.pem\\" intermediate/openssl.cnf

# Create an intermediate key and make sure to keep it secure.
openssl genrsa \
    -aes256 \
    -passout pass:${pwd} \
    -out intermediate/private/${intermediate_cert_name}.key.pem 4096
chmod 400 intermediate/private/${intermediate_cert_name}.key.pem

echo ""
echo "*** INTERMEDIATE KEY GENERATED ***"
echo ""


# Use the previously created key to create a certificate signing request (CSR).
openssl req -batch \
    -config intermediate/openssl.cnf \
    -new -sha256 \
    -passin pass:${pwd} \
    -key intermediate/private/${intermediate_cert_name}.key.pem \
    -out intermediate/csr/${intermediate_cert_name}.csr.pem
# chmod 444 ${root_folder}/csr/${intermediate_cert_name}.csr.pem

echo ""
echo "*** INTERMEDIATE CSR CREATED ***"
echo ""

# Use the root CA to sign the generated intermediate CSR.
openssl ca -batch \
    -config openssl.cnf \
    -passin pass:${pwd} \
    -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in intermediate/csr/${intermediate_cert_name}.csr.pem \
    -out intermediate/certs/${intermediate_cert_name}.cert.pem
chmod 444 intermediate/certs/${intermediate_cert_name}.cert.pem

echo ""
echo "*** INTERMEDIATE CSR SIGNED WITH ROOT CA ***"
echo ""

# Verify the intermediate certificate
openssl x509 \
    -noout -text \
    -in intermediate/certs/${intermediate_cert_name}.cert.pem

echo ""
echo ""

openssl verify \
    -CAfile certs/${root_cert_name}.cert.pem \
    intermediate/certs/${intermediate_cert_name}.cert.pem

echo ""
echo "CA Intermediate Certificate Generated At:"
echo "-----------------------------------------"
echo "intermediate/certs/${intermediate_cert_name}.cert.pem"
echo ""

echo "Create Root + Intermediate CA Chain Certificate"
echo "-----------------------------------"
cat intermediate/certs/${intermediate_cert_name}.cert.pem \
    certs/${root_cert_name}.cert.pem > \
    intermediate/certs/${chain_cert_name}.cert.pem
[ $? -eq 0 ] || exit $?
chmod 444 ${intermediate_folder}/certs/${chain_cert_name}.cert.pem
[ $? -eq 0 ] || exit $?

echo ""
echo "Root + Intermediate CA Chain Certificate Generated At:"
echo "------------------------------------------------------"
echo "    ${intermediate_folder}/certs/${chain_cert_name}.cert.pem"
echo ""
