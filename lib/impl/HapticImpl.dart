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

import 'dart:typed_data';

import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/module/Haptic.dart';

/**
 * Created by etsai on 9/18/16.
 */
class HapticImpl extends ModuleImplBase implements Haptic {
    static const int PULSE= 0x1;
    static const int BUZZER_DUTY_CYCLE= 127;

    static const DEFAULT_DUTY_CYCLE= 100.0;

    HapticImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);


    @override
    void startMotor(int pulseWidth, [double dutyCycle = DEFAULT_DUTY_CYCLE]) {
        int converted= ((dutyCycle / 100.0) * 248).floor();
        Uint8List payload = Uint8List(4);
        ByteData byteData = ByteData.view(payload.buffer);
        byteData.setInt8(0, (converted & 0xff));
        byteData.setInt16(1, (converted & 0xff),Endian.little);
        byteData.setInt8(3, (converted & 0xff));

        mwPrivate.sendCommandForModule(ModuleType.HAPTIC, PULSE, payload);
    }


    @override
    void startBuzzer(int pulseWidth) {
        Uint8List payload = Uint8List(4);
        ByteData byteData = ByteData.view(payload.buffer);
        byteData.setInt8(0, BUZZER_DUTY_CYCLE);
        byteData.setInt16(1, pulseWidth,Endian.little);
        byteData.setInt8(3, 1);
//        ByteBuffer buffer= ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).put(BUZZER_DUTY_CYCLE).putShort(pulseWidth).put((byte) 1);
        mwPrivate.sendCommandForModule(ModuleType.HAPTIC, PULSE, payload);
    }
}
