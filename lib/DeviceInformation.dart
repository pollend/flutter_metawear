/*
 * Copyright 2014-2015 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights granted under the terms of a software
 * license agreement between the user who downloaded the software, his/her employer (which must be your
 * employer) and MbientLab Inc, (the "License").  You may not use this Software unless you agree to abide by the
 * terms of the License which can be found at www.mbientlab.com/terms.  The License limits your use, and you
 * acknowledge, that the Software may be modified, copied, and distributed when used in conjunction with an
 * MbientLab Inc, product.  Other than for the foregoing purpose, you may not use, reproduce, copy, prepare
 * derivative works of, modify, distribute, perform, display or sell this Software and/or its documentation for any
 * purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS" WITHOUT WARRANTY
 * OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL MBIENTLAB OR ITS LICENSORS BE LIABLE OR
 * OBLIGATED UNDER CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED TO ANY INCIDENTAL, SPECIAL, INDIRECT,
 * PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software, contact MbientLab via email:
 * hello@mbientlab.com.
 */

import 'dart:core';

import 'package:sprintf/sprintf.dart';
import 'package:quiver/core.dart';

/**
 * Wrapper class holding Characteristics under the
 * <a href="https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.service.device_information.xml">Device Information</a>
 * GATT service
 * @author Eric Tsai
 */
class DeviceInformation {
    /** Device's manufacturer name, characteristic 0x2A29 */
    final String manufacturer;

    /** Model number assigned by MbientLab, characteristic 0x2A24 */
    final String modelNumber;

    /** Device's serial number, characteristic 0x2A25 */
    final String serialNumber;

    /** Revision of the firmware on the device, characteristic 0x2A26 */
    final String firmwareRevision;

    /** Revision of the hardware on the device, characteristic 0x2A27 */
    final String hardwareRevision;

    DeviceInformation({
        this.manufacturer,
        this.modelNumber,
        this.serialNumber,
        this.firmwareRevision,
        this.hardwareRevision
    });

    @override
    String toString() =>
        sprintf(
            "{manufacturer: %s, serialNumber: %s, firmwareRevision: %s, hardwareRevision: %s, modelNumber: %s}",
            [
                manufacturer,
                serialNumber,
                firmwareRevision,
                hardwareRevision,
                modelNumber
            ]);

    @override
    bool operator ==(other) =>
        other is DeviceInformation &&
            manufacturer == other.manufacturer &&
            modelNumber == other.modelNumber &&
            serialNumber == other.serialNumber &&
            firmwareRevision == other.firmwareRevision &&
            hardwareRevision == other.hardwareRevision;


    @override
    int get hashCode =>
        hashObjects([
            manufacturer,
            modelNumber,
            serialNumber,
            firmwareRevision,
            hardwareRevision
        ]);
}
