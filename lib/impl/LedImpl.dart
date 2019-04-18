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
import 'package:flutter_metawear/module/Led.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';

class _PatternEditor extends PatternEditor {

    final Uint8List command = Uint8List(17);
    final MetaWearBoardPrivate mwPrivate;

    _PatternEditor(Color color, this.mwPrivate) {
        command.setAll(0, Uint8List.fromList(
            [ModuleType.LED.id, LedImpl.CONFIG, color.index, 0x2]));

    }

    @override
    PatternEditor highIntensity(int intensity) {
        command[4] = intensity;
        return this;
    }

    @override
    PatternEditor lowIntensity(int intensity) {
        command[5] = intensity;
        return this;
    }

    @override
    PatternEditor riseTime(int time) {
        command[7] = ((time >> 8) & 0xff);
        command[6] = (time & 0xff);
        return this;
    }

    @override
    PatternEditor highTime(int time) {
        command[9] = ((time >> 8) & 0xff);
        command[8] = (time & 0xff);
        return this;
    }

    @override
    PatternEditor fallTime(int time) {
        command[11] = ((time >> 8) & 0xff);
        command[10] = (time & 0xff);
        return this;
    }

    @override
    PatternEditor pulseDuration(int duration) {
        command[13] = ((duration >> 8) & 0xff);
        command[12] = (duration & 0xff);
        return this;
    }

    @override
    PatternEditor delay(int delay) {
        if (mwPrivate
            .lookupModuleInfo(ModuleType.LED)
            .revision >= LedImpl.REVISION_LED_DELAYED) {
            command[15] = ((delay >> 8) & 0xff);
            command[14] = (delay & 0xff);
        } else {
            command[15] = 0;
            command[14] = 0;
        }
        return this;
    }

    @override
    PatternEditor repeatCount(int count) {
        command[16] = count;
        return this;
    }

    @override
    void commit() {
        mwPrivate.sendCommand(command);
    }
}

/**
 * Created by etsai on 8/31/16.
 */
class LedImpl extends ModuleImplBase implements Led {
    static const int PLAY = 0x1,
        STOP = 0x2,
        CONFIG = 0x3;
    static const int REVISION_LED_DELAYED = 1;

    LedImpl(MetaWearBoardPrivate mwPrivate) :super(mwPrivate);

    @override
    PatternEditor editPattern(Color ledColor, [PatternPreset preset]) {
        PatternEditor editor = _PatternEditor(ledColor, mwPrivate);
        switch (preset) {
            case PatternPreset.BLINK:
                editor.highIntensity(31)
                    .highTime(50)
                    .pulseDuration(500);
                break;
            case PatternPreset.PULSE:
                editor.highIntensity(31)
                    .riseTime(725)
                    .highTime(500)
                    .fallTime(725)
                    .pulseDuration(2000);
                break;
            case PatternPreset.SOLID:
                editor.highIntensity(31)
                    .lowIntensity(31)
                    .highTime(500)
                    .pulseDuration(1000);
                break;
        }
        return editor;
    }

    @override
    void autoplay() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.LED.id, PLAY, 2]));
    }

    @override
    void play() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.LED.id, PLAY, 1]));
    }

    @override
    void pause() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.LED.id, PLAY, 0]));
    }

    @override
    void stop(bool clear) {
        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.LED.id, STOP, (clear ? 1 : 0)]));
    }
}
