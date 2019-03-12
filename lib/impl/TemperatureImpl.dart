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

import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/SFloatData.dart';
import 'package:flutter_metawear/module/Temperature.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';

class TempSFloatData extends SFloatData {
  TempSFloatData(int id): super(ModuleType.TEMPERATURE, Util.setSilentRead(TemperatureImpl.VALUE), id, DataAttributes(new byte[] {2}, (byte) 1, (byte) 0, true));


  TempSFloatData(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
    super(input, module, register, id, attributes);
  }

  @override
  DataTypeBase copy(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
    return new TempSFloatData(input, module, register, id, attributes);
  }

  @override
  double scale(MetaWearBoardPrivate mwPrivate) {
    return 8.f;
  }
}


/**
 * Created by etsai on 9/18/16.
 */
class TemperatureImpl extends ModuleImplBase implements Temperature {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case VALUE:
                return String.format(Locale.US, "temperature[%d]", dataType.eventConfig[2]);
            default:
                return null;
        }
    }

    static const String PRODUCER_FORMAT= "com.mbientlab.metawear.impl.TemperatureImpl.PRODUCER_%d";
    static const int VALUE = 1, MODE= 2;


    private static class SensorImpl implements Sensor, Serializable {
        private static final long serialVersionUID = 6237752475101914419L;

        private final SensorType type;
        final byte channel;
        transient MetaWearBoardPrivate mwPrivate;

        private SensorImpl(SensorType type, byte channel, MetaWearBoardPrivate mwPrivate) {
            this.type = type;
            this.channel= channel;
            this.mwPrivate = mwPrivate;

            mwPrivate.tagProducer(name(), new TempSFloatData(channel));
        }

        void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
            this.mwPrivate = mwPrivate;
        }

        @override
        public Task<Route> addRouteAsync(RouteBuilder builder) {
            return mwPrivate.queueRouteBuilder(builder, name());
        }

        @override
        public String name() {
            return String.format(Locale.US, PRODUCER_FORMAT, channel);
        }

        @override
        public void read() {
            mwPrivate.lookupProducer(name()).read(mwPrivate);
        }

        @override
        public SensorType type() {
            return type;
        }
    }

    private static class ExternalThermistorImpl extends SensorImpl implements ExternalThermistor {
        private static final long serialVersionUID = 4055746069062728410L;

        private ExternalThermistorImpl(byte channel, MetaWearBoardPrivate mwPrivate) {
            super(SensorType.EXT_THERMISTOR, channel, mwPrivate);
        }

        @override
        public void configure(byte dataPin, byte pulldownPin, boolean activeHigh) {
            mwPrivate.sendCommand(new byte[] {TEMPERATURE.id, MODE, channel, dataPin, pulldownPin, (byte) (activeHigh ? 1 : 0)});
        }
    }

    private final SensorImpl[] sources;

    TemperatureImpl(MetaWearBoardPrivate mwPrivate) {
        super(mwPrivate);

        byte channel= 0;
        SensorType[] sensorTypes = SensorType.values();
        sources= new SensorImpl[mwPrivate.lookupModuleInfo(TEMPERATURE).extra.length];
        for(byte type: mwPrivate.lookupModuleInfo(TEMPERATURE).extra) {
            switch(sensorTypes[type]) {
                case NRF_SOC:
                    sources[channel]= new SensorImpl(SensorType.NRF_SOC, channel, mwPrivate);
                    break;
                case EXT_THERMISTOR:
                    sources[channel]= new ExternalThermistorImpl(channel, mwPrivate);
                    break;
                case BOSCH_ENV:
                    sources[channel]= new SensorImpl(SensorType.BOSCH_ENV, channel, mwPrivate);
                    break;
                case PRESET_THERMISTOR:
                    sources[channel]= new SensorImpl(SensorType.PRESET_THERMISTOR, channel, mwPrivate);
                    break;
            }
            channel++;
        }
    }

    @override
    public void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for(SensorImpl it: sources) {
            it.restoreTransientVars(mwPrivate);
        }
    }

    @override
    public Sensor[] sensors() {
        return sources;
    }

    @override
    public Sensor[] findSensors(SensorType type) {
        ArrayList<Integer> matchIndices= new ArrayList<>();
        for(int i= 0; i < sources.length; i++) {
            if (sources[i].type() == type) {
                matchIndices.add(i);
            }
        }

        if (matchIndices.isEmpty()) {
            return null;
        }

        Sensor[] matches= new Sensor[matchIndices.size()];
        int i= 0;
        for(Integer it: matchIndices) {
            matches[i]= sources[it];
            i++;
        }
        return matches;
    }
}
