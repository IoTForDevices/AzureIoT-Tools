# IoT Certificate Creation

In this folder you will find a number of scripts in different folders to create different X.509 certificates.
All these certificates are self-signed, including the root certificate, which should be kept as a secret.

Types of certificates that will be used:

- Root Certificate (root of trust)
- Intermediate Certificate (stored in IoT Hub / DPS and used to generate IoT Device Certificates)
- Verification Certificate (used to verify the uploaded Intermediate certificate)
- Device Certificates in different formats, created with the Intermediate Certificate

Even though these scripts can be executed stand-alone, they are meant to be called from higher level sample scenarios, for instance to use X.509 certificates in combination with an IoT Hub or a DPS Service.
