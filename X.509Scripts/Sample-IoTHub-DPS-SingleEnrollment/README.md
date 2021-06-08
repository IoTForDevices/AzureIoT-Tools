# IoTHub with DPS - Single Device Enrollment

There are two different types of device certificates you can use to create a new device.

1. Use a certificate chain of trust (including a CA) to create your device certificate. These certificates work great in combination with the 'high-level' Azure IoT SDK's. More information can be found [in this document](./CREATE-CA-CHAIN.md).
2. Use a self-signed device certificate. These certificates can be used in combination with the Azure IoT SDK for Embedded C for devices that are running on Azure RTOS. More information can be found [in this document](./CREATE-SELF-SIGNED.md).

