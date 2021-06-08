# Create X.509 self-signed certificate to securely connect a single device to an IoT Central application

IoT Central supports both shared access signatures (SAS) and X.509 certificates to secure the communication between a device and the application.
In this folder you will find a script to create a X.509 self-signed certificate in its own directory

## Prerequisites

- WSL(2) with Ubuntu 18.04 or later installed
- Individual Enrollment created as described in [this document](https://docs.microsoft.com/en-us/azure/iot-central/core/how-to-connect-devices-x509#create-individual-enrollment)

In individual enrollments you don't need to install a root or intermediate X.509 certificate in your IoT Central application. Devices use a self-signed X.509 certificate to connect to your application.

## Generate a self-signed device certificate

Execute the script that can be found in this folder and pass a root-folder and a device name where the self signed device certificate will be created.

``` sh
./create-single-enrollment-azure-rtos.sh --root-folder /mnt/c/Source/Keys/mst01-tst --registration-id mst01
```

Executing the above shown script creates a new folder (it removes it first if a folder with the same name already exists) to store all certificate files in.

The script creates the following files in the specified folder:

![self-signed device key files](../Media/img_SelfSignedDeviceCertificate.png)

The actual certificates (*.cert.pem) can be uploaded to an IoT Central application's individual enrollment. The actual certificate and private key are also stored in the device firmware. For this reason they are converted to two different C arrays that can be found in the file ```cert.c```.

> NOTE: Make sure that you use the same name for device-id in the IoT Central application and the registration-id in the script. The registration-id can only contain alphanumerics and “-“ – but no spaces.