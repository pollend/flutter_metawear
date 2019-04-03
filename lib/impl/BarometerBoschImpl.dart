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


import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/SFloatData.dart';
import 'package:flutter_metawear/impl/UFloatData.dart';
import 'package:flutter_metawear/module/BarometerBosch.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'dart:typed_data';


class BoschPressureUFloatData extends UFloatData {

    BoschPressureUFloatData.Default(): super(ModuleType.BAROMETER, BarometerBoschImpl.PRESSURE, new DataAttributes(Uint8List.fromList([4]), 1, 0, false));


    BoschPressureUFloatData(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes): super(module, register, attributes,id:id,input:input,);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        return new BoschPressureUFloatData(input, module, register, id, attributes);
    }

    @override
    double scale(MetaWearBoardPrivate mwPrivate) {
        return 256.0;
    }
}
class BoschAltitudeSFloatData extends SFloatData {

    BoschAltitudeSFloatData() :   super(ModuleType.BAROMETER, BarometerBoschImpl.ALTITUDE, new DataAttributes(Uint8List.fromList([4]), 1, 0, true));


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        return new BoschPressureUFloatData(input, module, register, id, attributes);
    }

    @override
    double scale(MetaWearBoardPrivate mwPrivate) {
        return 256.0;
    }
}

class _PressureAsyncDataProducer extends AsyncDataProducer{
    final BarometerBoschImpl _impl;

  _PressureAsyncDataProducer(this._impl);


    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return this._impl.mwPrivate.queueRouteBuilder(builder, BarometerBoschImpl.PRESSURE_PRODUCER);
    }

    @override
    String name() {
        return BarometerBoschImpl.PRESSURE_PRODUCER;
    }

    @override
    void start() {

    }

    @override
    void stop() {

    }

}

class _AltitudeAsyncDataProducer extends AsyncDataProducer{
    final BarometerBoschImpl _impl;

    _AltitudeAsyncDataProducer(this._impl);

    @override
     Future<Route> addRouteAsync(RouteBuilder builder) {
        return _impl.mwPrivate.queueRouteBuilder(builder, BarometerBoschImpl.ALTITUDE_PRODUCER);
    }

    @override
     String name() {

        return BarometerBoschImpl.ALTITUDE_PRODUCER;
    }

    @override
     void start() {
        _impl.enableAltitude= 1;
    }

    @override
     void stop() {
        _impl.enableAltitude= 0;
    }

}

/**
 * Created by etsai on 9/20/16.
 */
abstract class BarometerBoschImpl extends ModuleImplBase implements BarometerBosch{
    static String createUri(DataTypeBase dataType) {
        switch (dataType.eventConfig[1]) {
            case PRESSURE:
                return "pressure";
            case ALTITUDE:
                return "altitude";
            default:
                return null;
        }
    }

    static const String PRESSURE_PRODUCER= "com.mbientlab.metawear.impl.BarometerBoschImpl.PRESSURE_PRODUCER",
            ALTITUDE_PRODUCER= "com.mbientlab.metawear.impl.BarometerBoschImpl.ALTITUDE_PRODUCER";
    static const int PRESSURE = 1, ALTITUDE = 2, CYCLIC = 4;
    static const int CONFIG = 3;


    int enableAltitude= 0;

    BarometerBoschImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate){
        mwPrivate.tagProducer(PRESSURE_PRODUCER, new BoschPressureUFloatData.Default());
        mwPrivate.tagProducer(ALTITUDE_PRODUCER, new BoschAltitudeSFloatData());
    }

    @override
    AsyncDataProducer pressure() {
        return _PressureAsyncDataProducer(this);
    }

    @override
    AsyncDataProducer altitude() {
        return _AltitudeAsyncDataProducer(this);
    }

    @override
    void start() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.BAROMETER.id, CYCLIC, 1, enableAltitude]));
    }

    @override
    void stop() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.BAROMETER.id, CYCLIC, 0, 0]));
    }
}
