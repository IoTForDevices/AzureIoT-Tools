# Create a certificate chain of trust (including a CA) to create your device certificate

Using the CreateCerts and InstallCerts scripts, we create a new device that will be signed with an X.509 certificate and connects to the IoTHub corresponding to the Device Provisioning Service. Different devices have different ways to install the X.509 device certificates (in our samples typically in source code, in production this should be avoided and instead, be done through TPM or other HSM solutions).

## Introduction

This repository contains a number of bash scripts that can help you to create / install / validate X.509 certificates for use with an Azure IoT Hub with an associated Device Provisioning Service. There are also scripts that can create device identities with corresponding device certificates. More information on securing IoT Hubs with X.509
certificates can be found in the [Microsoft documentatation](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-security-x509-get-started)

Pre-requisites: You must login to the right Azure subscription using az-cli prior to invoking the scripts. You also must have an IoT Hub with an associated Device Provisioning Service ready to use.

## Workflow

This repository contains a collection of scripts that will help you create X.509 certificates and install them in DPS for a single device enrollment. These scripts work in a Linux environment and have been tested with Ubuntu 18.04 LTS. The scripts should also work in WSL[2].

The following folder structure is used:
- AzureIoT-Tools (Repo Root)
  - Sample-IoTHub-DPS-SingleEnrollment
      - create-dps-single-enrollment.sh (scripts to create / install X.509 certificates)

---
TODO
1) Create all necessary certificates by invoking ```add-iothub-certificates.sh``` with proper parameters. You will be prompted for a password to protect the private key you are going to create.

``` bash
Scripts/add-iothub-certificate.sh \
    --iot-hub iot-f-mst01 \
    --root-folder ~/ca-mst01 \
    --cert-name mst01    
```

TODO
***

## Using OpenSSL

The workflow described here is good for test purposes and to secure IoT maker solutions. Here is a [nice simple article on using OpenSSL](https://blog.ipswitch.com/how-to-use-openssl-to-generate-certificates).
In Enterprise Environments, it is strongly advices to make use of X.509 certificates from a root certificate authority (CA).