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


import 'package:flutter_blue/flutter_blue.dart';

/**
 * Bluetooth GATT characteristic
 * @author Eric Tsai
 */
class BtleGattCharacteristic {
    /** UUID identifying the service the characteristic belongs to */
    final Guid serviceUuid;

    /** UUID identifying the characteristic */
    final Guid uuid;

    BtleGattCharacteristic({Guid this.serviceUuid, Guid this.uuid});


    @override
    int get hashCode => serviceUuid.hashCode * 31 + uuid.hashCode;

    @override
    bool operator ==(o) {
        if (this == o) return true;
        if (o == null || runtimeType != o.runtimeType) return false;

        BtleGattCharacteristic that = o as BtleGattCharacteristic;

        return serviceUuid == that.serviceUuid && uuid == that.uuid;
    }
//
//
//
//    @override
//    public boolean equals(Object o) {
//        if (this == o) return true;
//        if (o == null || getClass() != o.getClass()) return false;
//
//        BtleGattCharacteristic that = (BtleGattCharacteristic) o;
//
//        return serviceUuid.equals(that.serviceUuid) && uuid.equals(that.uuid);
//
//    }
//
//    @override
//    public int hashCode() {
//        int result = serviceUuid.hashCode();
//        result = 31 * result + uuid.hashCode();
//        return result;
//    }
}
