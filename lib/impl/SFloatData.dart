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

import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'ModuleType.dart';
import 'DataAttributes.dart';
import 'DataTypeBase.dart';
import 'package:tuple/tuple.dart';
import 'DataPrivate.dart';
class _DataPrivate extends DataPrivate{
    final MetaWearBoardPrivate mwPrivate;
    final SFloatData sFloatData;
    final double scaled;

    _DataPrivate(DateTime timestamp, Uint8List dataBytes, ClassToObject mapper, this.mwPrivate,this.sFloatData,this.scaled) : super(timestamp, dataBytes, mapper);


    @override
    double scale() => sFloatData.scale(mwPrivate);

    @override
    List<Type> types() => [double];

    @override
    dynamic value(Type clazz) {
        if (clazz == double) {
            return scaled;
        }
        return super.value(clazz);
    }
}


/**
 * Created by etsai on 9/5/16.
 */
class SFloatData extends DataTypeBase {

    SFloatData(ModuleType module, int register, DataAttributes attributes, Function split,{int id, DataTypeBase input}): super(module,register,attributes,split,id:id,input:input);


    @override
    DataTypeBase copy(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        if (input == null) {
            if (this.input == null) {
                throw new NullPointerException("SFloatData cannot have null input variable");
            }
            return this.input.copy(null, module, register, id, attributes);
        }

        return new SFloatData(input, module, register, id, attributes);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, Number value) {
        return value.floatValue() * scale(mwPrivate);
    }

    @override
    Data createMessage(boolean logData, final MetaWearBoardPrivate mwPrivate, final byte[] data, final Calendar timestamp, DataPrivate.ClassToObject mapper) {
        final ByteBuffer buffer = Util.bytesToSIntBuffer(logData, data, attributes);
        final float scaled= buffer.getInt(0) / scale(mwPrivate);

        return new DataPrivate(timestamp, data, mapper) {
            @override
            public float scale() {
                return SFloatData.this.scale(mwPrivate);
            }

            @override
            public Class<?>[] types() {
                return new Class<?>[] {Float.class};
            }

            @override
            public <T> T value(Class<T> clazz) {
                if (clazz.equals(Float.class)) {
                    return clazz.cast(scaled);
                }
                return super.value(clazz);
            }
        };
    }

    @override
    Tuple2<DataTypeBase,DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch(config.id) {
            case DataProcessorConfig.Maths.ID: {
                DataProcessorConfig.Maths casted = (DataProcessorConfig.Maths) config;
                switch(casted.op) {
                    case ABS_VALUE: {
                        DataAttributes copy= attributes.dataProcessorCopySigned(false);
                        return new Pair<>(new UFloatData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, copy), null);
                    }
                }
                break;
            }
        }
        return super.dataProcessorTransform(config, dpModule);
    }

}
