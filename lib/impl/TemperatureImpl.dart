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

import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/SFloatData.dart';
import 'package:flutter_metawear/module/Temperature.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'dart:typed_data';
import 'package:flutter_metawear/Route.dart';
import 'package:sprintf/sprintf.dart';


class TempSFloatData extends SFloatData {
    TempSFloatData.ById(int id): super(ModuleType.TEMPERATURE, Util.setSilentRead(TemperatureImpl.VALUE), new DataAttributes(Uint8List.fromList([2]), 1, 0, true),id:id);


    TempSFloatData(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes): super(module, register, attributes,id:id,input:input);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        return new TempSFloatData(input, module, register, id, attributes);
    }

    @override
    double scale(MetaWearBoardPrivate mwPrivate) {
        return 8.0;
    }
}

class SensorImpl implements Sensor{

    final SensorType _type;
    final int channel;
    MetaWearBoardPrivate mwPrivate;

    SensorImpl(this._type, this.channel, this.mwPrivate) {
        mwPrivate.tagProducer(name(), new TempSFloatData.ById(channel));
    }

    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate = mwPrivate;
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, name());
    }

    @override
    String name() {
        return sprintf(TemperatureImpl.PRODUCER_FORMAT, channel);
    }

    @override
    void read() {
        mwPrivate.lookupProducer(name()).read(mwPrivate);
    }

    @override
    SensorType type() {
        return _type;
    }
}

class ExternalThermistorImpl extends SensorImpl implements ExternalThermistor {

    ExternalThermistorImpl(int channel, MetaWearBoardPrivate mwPrivate) : super(SensorType.EXT_THERMISTOR, channel, mwPrivate);


    @override
    void configure(int dataPin, int pulldownPin, bool activeHigh) {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.TEMPERATURE.id, TemperatureImpl.MODE, channel, dataPin, pulldownPin, (activeHigh ? 1 : 0)]));
    }
}


/**
 * Created by etsai on 9/18/16.
 */
class TemperatureImpl extends ModuleImplBase implements Temperature {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case VALUE:
                return sprintf("temperature[%d]", dataType.eventConfig[2]);
            default:
                return null;
        }
    }

    static const String PRODUCER_FORMAT = "com.mbientlab.metawear.impl.TemperatureImpl.PRODUCER_%d";
    static const int VALUE = 1,
        MODE = 2;


    final List<SensorImpl> sources;

    TemperatureImpl(MetaWearBoardPrivate mwPrivate)
        :sources = List<SensorImpl>(mwPrivate
        .lookupModuleInfo(ModuleType.TEMPERATURE)
        .extra
        .length),
            super(mwPrivate) {
        int channel = 0;
        List<SensorType> sensorTypes = SensorType.values;
        for (int type in mwPrivate
            .lookupModuleInfo(ModuleType.TEMPERATURE)
            .extra) {
            switch (sensorTypes[type]) {
                case SensorType.NRF_SOC:
                    sources[channel] =
                    new SensorImpl(SensorType.NRF_SOC, channel, mwPrivate);
                    break;
                case SensorType.EXT_THERMISTOR:
                    sources[channel] =
                    new ExternalThermistorImpl(channel, mwPrivate);
                    break;
                case SensorType.BOSCH_ENV:
                    sources[channel] =
                    new SensorImpl(SensorType.BOSCH_ENV, channel, mwPrivate);
                    break;
                case SensorType.PRESET_THERMISTOR:
                    sources[channel] = new SensorImpl(
                        SensorType.PRESET_THERMISTOR, channel, mwPrivate);
                    break;
            }
            channel++;
        }
    }

    @override
    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for (SensorImpl it in sources) {
            it.restoreTransientVars(mwPrivate);
        }
    }

    @override
    List<Sensor> sensors() {
        return sources;
    }

    @override
    List<Sensor> findSensors(SensorType type) {
        List<int> matchIndices = [];
        for (int i = 0; i < sources.length; i++) {
            if (sources[i].type() == type) {
                matchIndices.add(i);
            }
        }

        if (matchIndices.isEmpty) {
            return null;
        }

        List<Sensor> matches = List<Sensor>(matchIndices.length);
        int i = 0;
        for (int it in matchIndices) {
            matches[i] = sources[it];
            i++;
        }
        return matches;
    }
}
