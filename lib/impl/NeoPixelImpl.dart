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
import 'package:flutter_metawear/module/NeoPixel.dart';


class _Strand extends Strand {
    final Map<int, int> _activeStrands;
    final MetaWearBoardPrivate _mwPrivate;
    final int strand;
    final int length;

  _Strand(this._activeStrands,this._mwPrivate, this.length,this.strand);

    @override
    void free() {
        _activeStrands.remove(strand);
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.FREE, strand]));
    }

    @override
    void hold() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.HOLD, strand, 1]));
    }

    @override
    void release() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.HOLD, strand,  0]));
    }

    @override
    void clear(int start, int end) {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.CLEAR, strand, start, end]));
    }

    @override
    void setRgb(int index, int red, int green, int blue) {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.SET_COLOR, strand, index, red, green, blue]));
    }

    void rotate(RotationDirection direction, int period,[int repetitions]){
      _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.ROTATE, strand, direction.index, repetitions == null ? -1 : repetitions, (period & 0xff), (period >> 8 & 0xff)]));
    }

    @override
    void stopRotation() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, NeoPixelImpl.ROTATE, strand, 0x0, 0x0, 0x0, 0x0]));
    }

    @override
    int nLeds() {
        return length;
    }

}

/**
 * Created by etsai on 9/18/16.
 */
class NeoPixelImpl extends ModuleImplBase implements NeoPixel {
    static const int INITIALIZE= 1,
            HOLD= 2,
            CLEAR= 3, SET_COLOR= 4,
            ROTATE= 5,
            FREE= 6;
    final Map<int, int> activeStrands = Map();

    NeoPixelImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate);

    @override
    Strand initializeStrand(int strand, ColorOrdering ordering, StrandSpeed speed, int gpioPin, int length) {
        activeStrands[strand] =  length;
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.NEO_PIXEL.id, INITIALIZE, strand, (speed.index << 2 | ordering.index), gpioPin, length]));
        return _createStrandObj(strand, length);
    }

    @override
    Strand lookupStrand(int strand) {
        if (activeStrands.containsKey(strand)) {
            return _createStrandObj(strand, activeStrands[strand]);
        }
        return null;
    }

    Strand _createStrandObj(final int strand, final int length) => _Strand(activeStrands, mwPrivate, length, strand);
}
