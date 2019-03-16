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

import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/UFloatData.dart';
import 'package:flutter_metawear/module/HumidityBme280.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';

class HumidityBme280SFloatData extends UFloatData {
    HumidityBme280SFloatData.Default() : super(
        ModuleType.HUMIDITY, Util.setSilentRead(HumidityBme280Impl.VALUE),
        new DataAttributes(Uint8List.fromList([4]), 1, 0, false));

    HumidityBme280SFloatData(DataTypeBase input, ModuleType module,
        int register, int id, DataAttributes attributes)
        : super(module, register, attributes, input: input, id: id);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new HumidityBme280SFloatData(
            input, module, register, id, attributes);
    }

    @override
    double scale(MetaWearBoardPrivate mwPrivate) {
        return 1024.0;
    }
}

class _ForcedDataProducer extends ForcedDataProducer {

    final MetaWearBoardPrivate mwPrivate;

    _ForcedDataProducer(this.mwPrivate);

    void read() {
        mwPrivate.lookupProducer(HumidityBme280Impl.PRODUCER).read(mwPrivate);
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(
            builder, HumidityBme280Impl.PRODUCER);
    }

    @override
    String name() {
        return HumidityBme280Impl.PRODUCER;
    }
}

/**
 * Created by etsai on 9/19/16.
 */
class HumidityBme280Impl extends ModuleImplBase implements HumidityBme280 {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case VALUE:
                return "relative-humidity";
            default:
                return null;
        }
    }

    static const String PRODUCER= "com.mbientlab.metawear.impl.HumidityBme280Impl.PRODUCER";
    static const int VALUE = 1, MODE = 2;


    ForcedDataProducer humidityProducer;

    HumidityBme280Impl(MetaWearBoardPrivate mwPrivate): super(mwPrivate){

        mwPrivate.tagProducer(PRODUCER, new HumidityBme280SFloatData.Default());
    }

    @override
    void setOversampling(OversamplingMode mode) {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.HUMIDITY.id, HumidityBme280Impl.MODE, (mode.index + 1)]));
    }

    @override
    ForcedDataProducer value() {
        if (humidityProducer == null) {
            humidityProducer = _ForcedDataProducer(mwPrivate);
        }
        return humidityProducer;
    }
}
