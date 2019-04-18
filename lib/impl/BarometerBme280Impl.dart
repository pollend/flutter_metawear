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


import 'package:flutter_metawear/impl/BarometerBoschImpl.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/module/BarometerBme280.dart' as BarometerBme280 ;
import 'package:flutter_metawear/module/BarometerBosch.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'dart:typed_data';

class _Configure implements BarometerBme280.ConfigEditor {
    OversamplingMode samplingMode = OversamplingMode.STANDARD;
    FilterCoeff _filterCoeff = FilterCoeff.OFF;
    BarometerBme280.StandbyTime _time = BarometerBme280.StandbyTime.TIME_0_5;
    int _tempOversampling = 1;

    final MetaWearBoardPrivate _mwPrivate;

    _Configure(this._mwPrivate);

    @override
    BarometerBme280.ConfigEditor standbyTime(BarometerBme280.StandbyTime time) {
        this._time = time;
        return this;
    }

    @override
    void commit() {
        _mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.BAROMETER.id, BarometerBoschImpl.CONFIG,
            ((samplingMode.index << 2) | (_tempOversampling << 5)),
            ((_filterCoeff.index << 2) | (_time.index << 5))
            ]));
    }

    @override
    BarometerBme280.ConfigEditor pressureOversampling(OversamplingMode mode) {
        samplingMode = mode;
        _tempOversampling = ((mode == OversamplingMode.ULTRA_HIGH) ? 2 : 1);
        return this;
    }

    @override
    BarometerBme280.ConfigEditor filterCoeff(FilterCoeff coeff) {
        _filterCoeff = coeff;
        return this;
    }
}

/**
 * Created by etsai on 9/20/16.
 */
class BarometerBme280Impl extends BarometerBoschImpl implements BarometerBme280.BarometerBme280 {
    static const int IMPLEMENTATION = 1;

    BarometerBme280Impl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);


    @override
    BarometerBme280.ConfigEditor configure() {
        return _Configure(mwPrivate);
    }
}
