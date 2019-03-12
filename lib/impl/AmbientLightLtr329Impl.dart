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

import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/module/AmbientLightLtr329.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';

import 'dart:typed_data';

class _configEditor extends ConfigEditor {
    Gain ltr329Gain= Gain.LTR329_1X;
    IntegrationTime ltr329Time= IntegrationTime.LTR329_TIME_100MS;
    MeasurementRate ltr329Rate= MeasurementRate.LTR329_RATE_500MS;
    final MetaWearBoardPrivate mwPrivate;

  _configEditor(this.mwPrivate);

    @override
    ConfigEditor gain(Gain sensorGain) {
        ltr329Gain= sensorGain;
        return this;
    }

    @override
    ConfigEditor integrationTime(IntegrationTime time) {
        ltr329Time= time;
        return this;
    }

    @override
    ConfigEditor measurementRate(MeasurementRate rate) {
        ltr329Rate= rate;
        return this;
    }

    @override
    void commit() {
        int alsContr= (ltr329Gain.bitmask << 2);
        int alsMeasRate= ((ltr329Time.bitmask << 3) | ltr329Rate.index);

        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.AMBIENT_LIGHT.id, AmbientLightLtr329Impl.CONFIG, alsContr, alsMeasRate]));
    }
}

class _AsyncDataProducer extends AsyncDataProducer{
    final MetaWearBoardPrivate mwPrivate;

    _AsyncDataProducer(this.mwPrivate);

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, AmbientLightLtr329Impl.ILLUMINANCE_PRODUCER);
    }

    @override
    String name() {
        return AmbientLightLtr329Impl.ILLUMINANCE_PRODUCER;
    }

    @override
    void start() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.AMBIENT_LIGHT.id, AmbientLightLtr329Impl.ENABLE, 0x1]));
    }

    @override
    void stop() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.AMBIENT_LIGHT.id, AmbientLightLtr329Impl.ENABLE, 0x0]));
    }

}


/**
 * Created by etsai on 9/20/16.
 */
class AmbientLightLtr329Impl extends ModuleImplBase implements AmbientLightLtr329 {
    static String createUri(DataTypeBase dataType) {
        switch (dataType.eventConfig[1]) {
            case OUTPUT:
                return "illuminance";
            default:
                return null;
        }
    }

    static const String ILLUMINANCE_PRODUCER= "com.mbientlab.metawear.impl.AmbientLightLtr329Impl.ILLUMINANCE_PRODUCER";
    static const int ENABLE = 1, CONFIG = 2, OUTPUT = 3;

    AsyncDataProducer illuminanceProducer;

    AmbientLightLtr329Impl(MetaWearBoardPrivate mwPrivate): super(mwPrivate){
        mwPrivate.tagProducer(ILLUMINANCE_PRODUCER, new MilliUnitsUFloatData(ModuleType.AMBIENT_LIGHT, OUTPUT, new DataAttributes(new byte[] {4}, (byte) 1, (byte) 0, false)));
    }

    @override
    ConfigEditor configure() {
        return _configEditor(mwPrivate);
    }

    @override
    AsyncDataProducer illuminance() {
        if (illuminanceProducer == null) {
            illuminanceProducer = _AsyncDataProducer(mwPrivate);
        }
        return illuminanceProducer;
    }
}
