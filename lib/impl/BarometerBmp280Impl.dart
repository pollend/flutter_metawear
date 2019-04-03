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
 * Should you have any questions regarding your right to use this Software, contact MbientLab via email:
 * hello@mbientlab.com.
 */


import 'package:flutter_metawear/impl/BarometerBoschImpl.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/module/BarometerBosch.dart';
import 'package:flutter_metawear/module/BarometerBmp280.dart' as BarometerBmp280;
import 'dart:typed_data';
import 'package:flutter_metawear/impl/ModuleType.dart';

class _ConfigEditor extends BarometerBmp280.ConfigEditor {
    OversamplingMode samplingMode = OversamplingMode.STANDARD;
    FilterCoeff _filterCoeff = FilterCoeff.OFF;
    BarometerBmp280.StandbyTime _time = BarometerBmp280.StandbyTime.TIME_0_5;
    int tempOversampling = 1;

    final MetaWearBoardPrivate _mwPrivate;

    _ConfigEditor(this._mwPrivate);

    @override
    BarometerBmp280.ConfigEditor standbyTime(BarometerBmp280.StandbyTime time) {
        this._time = time;
        return this;
    }

    @override
    void commit() {
        _mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.BAROMETER.id, BarometerBoschImpl.CONFIG,
            ((samplingMode.index << 2) | (tempOversampling << 5)),
            ((_filterCoeff.index << 2) | (_time.index << 5))
            ]));
    }

    @override
    BarometerBmp280.ConfigEditor pressureOversampling(OversamplingMode mode) {
        samplingMode = mode;
        tempOversampling = ((mode == OversamplingMode.ULTRA_HIGH) ? 2 : 1);
        return this;
    }

    @override
    BarometerBmp280.ConfigEditor filterCoeff(FilterCoeff coeff) {
        _filterCoeff = coeff;
        return this;
    }
}

/**
 * Created by etsai on 9/20/16.
 */
class BarometerBmp280Impl extends BarometerBoschImpl implements BarometerBmp280.BarometerBmp280 {
    BarometerBmp280Impl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);

    @override
    BarometerBmp280.ConfigEditor configure() {
        return _ConfigEditor(mwPrivate);
    }

}
