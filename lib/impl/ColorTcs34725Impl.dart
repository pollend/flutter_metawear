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


import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/ColorTcs34725.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'dart:typed_data';

class _DataPrivate extends DataPrivate {
    final ColorAdc colorAdc;

    _DataPrivate(this.colorAdc, DateTime timestamp, Uint8List dataBytes,
        ClassToObject mapper) : super(timestamp, dataBytes, mapper);

    @override
    List<Type> types() {
        return [ColorAdc];
    }

    @override
    T value<T>() {
        if (T is ColorAdc)
            return colorAdc as T;
        return value<T>();
    }
}

class ColorAdcData extends DataTypeBase {
    ColorAdcData.Default() : super(
        ModuleType.COLOR_DETECTOR, Util.setSilentRead(ColorTcs34725Impl.ADC),
        new DataAttributes(Uint8List.fromList([2, 2, 2, 2]), 1, 0, false));


    ColorAdcData(DataTypeBase input, ModuleType module, int register, int id,
        DataAttributes attributes)
        : super(module, register, attributes, input: input, id: id);

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new ColorAdcData(input, module, register, id, attributes);
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, ClassToObject mapper) {
        ByteData byteData = ByteData.view(data.buffer);

        final ColorAdc wrapper = new ColorAdc(
            byteData.getInt16(0, Endian.little) & 0xffff,
            byteData.getInt16(2, Endian.little) & 0xffff,
            byteData.getInt16(4, Endian.little) & 0xffff,
            byteData.getInt16(6, Endian.little) & 0xffff
        );

        return _DataPrivate(wrapper, timestamp, data, mapper);
    }

    @override
    List<DataTypeBase> createSplits() {
        return [
            ColorTcs34725Impl.createAdcUintDataProducer(0),
            ColorTcs34725Impl.createAdcUintDataProducer(2),
            ColorTcs34725Impl.createAdcUintDataProducer(4),
            ColorTcs34725Impl.createAdcUintDataProducer(6)
        ];
    }



    @override
    Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(
        DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch (config.id) {
            case Combiner.ID:
                {
                    DataAttributes attributes = new DataAttributes(
                        new byte[] {this.attributes.sizes[0]}, (byte) 1, (byte)
                        0,
                        false);
                    return new Pair<>(new UintData(
                        this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                        attributes), null);
                }
        }

        return super.dataProcessorTransform(config, dpModule);
    }

}

class _ConfigEditor extends ConfigEditor{
    static const int aTime =  0xff;
    Gain _gain = Gain.TCS34725_1X;
    int illuminate= 0;

    @override
    ConfigEditor integrationTime(double time) {
        aTime =  (256 - time / 2.4);
        return this;
    }

    @override
    ConfigEditor gain(Gain gain) {
        this._gain = gain;
        return this;
    }

    @override
    ConfigEditor enableIlluminatorLed() {
        illuminate= 1;
        return this;
    }

    @override
    void commit() {
        mwPrivate.sendCommand(new byte[] {ModuleType.COLOR_DETECTOR.id, ColorTcs34725Impl.MODE, aTime, _gain.index, illuminate});
    }
}

/**
 * Created by etsai on 9/19/16.
 */
class ColorTcs34725Impl extends ModuleImplBase implements ColorTcs34725 {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case ADC:
                return dataType.attributes.length() > 2 ? "color" : String.format(Locale.US, "color[%d]", (dataType.attributes.offset >> 1));
            default:
                return null;
        }
    }

    static const String ADC_PRODUCER= "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_PRODUCER",
            ADC_CLEAR_PRODUCER= "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_CLEAR_PRODUCER",
            ADC_RED_PRODUCER= "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_RED_PRODUCER",
            ADC_GREEN_PRODUCER= "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_GREEN_PRODUCER",
            ADC_BLUE_PRODUCER= "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_BLUE_PRODUCER";
    static const int ADC = 1, MODE = 2;

    static UintData createAdcUintDataProducer(int offset) {
        return new UintData(ModuleType.COLOR_DETECTOR, Util.setSilentRead(ADC), DataAttributes(Uint8List.fromList([2]), 1, offset, true));
    }

    private transient ColorAdcDataProducer adcProducer;

    ColorTcs34725Impl(MetaWearBoardPrivate mwPrivate): super(mwPrivate){

        DataTypeBase adcProducer = new ColorAdcData();
        this.mwPrivate.tagProducer(ADC_PRODUCER, adcProducer);
        this.mwPrivate.tagProducer(ADC_CLEAR_PRODUCER, adcProducer.split[0]);
        this.mwPrivate.tagProducer(ADC_RED_PRODUCER, adcProducer.split[1]);
        this.mwPrivate.tagProducer(ADC_GREEN_PRODUCER, adcProducer.split[2]);
        this.mwPrivate.tagProducer(ADC_BLUE_PRODUCER, adcProducer.split[3]);
    }

    @override
    public ConfigEditor configure() {
        return new ConfigEditor() {
            private byte aTime= (byte) 0xff;
            private Gain gain= Gain.TCS34725_1X;
            private byte illuminate= 0;

            @override
            public ConfigEditor integrationTime(float time) {
                aTime= (byte) (256.f - time / 2.4f);
                return this;
            }

            @override
            public ConfigEditor gain(Gain gain) {
                this.gain= gain;
                return this;
            }

            @override
            public ConfigEditor enableIlluminatorLed() {
                illuminate= 1;
                return this;
            }

            @override
            public void commit() {
                mwPrivate.sendCommand(new byte[] {COLOR_DETECTOR.id, MODE, aTime, (byte) gain.ordinal(), illuminate});
            }
        };
    }

    @override
    ColorAdcDataProducer adc() {
        if (adcProducer == null) {
            adcProducer = new ColorAdcDataProducer() {
                @override
                public void read() {
                    mwPrivate.lookupProducer(ADC_PRODUCER).read(mwPrivate);
                }

                @override
                public String clearName() {
                    return ADC_CLEAR_PRODUCER;
                }

                @override
                public String redName() {
                    return ADC_RED_PRODUCER;
                }

                @override
                public String greenName() {
                    return ADC_GREEN_PRODUCER;
                }

                @override
                public String blueName() {
                    return ADC_BLUE_PRODUCER;
                }

                @override
                public Task<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, ADC_PRODUCER);
                }

                @override
                public String name() {
                    return ADC_PRODUCER;
                }
            };
        }
        return adcProducer;
    }
}
