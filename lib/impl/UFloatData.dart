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

import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/builder/RouteComponent.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/SFloatData.dart';
import 'package:flutter_metawear/impl/Util.dart';

import 'package:tuple/tuple.dart';

/**
 * Created by etsai on 9/5/16.
 */
class UFloatData extends DataTypeBase {
    UFloatData(ModuleType module, int register, DataAttributes attributes,{int id, DataTypeBase input}) : super(module, register, attributes,id:id,input:input);

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        if (input == null) {
            if (this.input == null) {
                throw NullThrownError();
            }
            return this.input.copy(null, module, register, id, attributes);
        }

        return new UFloatData(
            module, register, attributes, id: id, input: input);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value.toDouble() * scale(mwPrivate);
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, DateTime timestamp, T Function<T>() apply) {
        Uint8List buffer = Util.bytesToUIntBuffer(logData, data, attributes);
        final double scaled = ByteData.view(buffer.buffer).getUint64(
            0, Endian.little) / scale(mwPrivate);
        DataPrivate2(
            timestamp, data, apply, () => this.scale(mwPrivate), <T>() {
            if (T is double) {
                return scaled as T;
            }
            throw CastError();
        });
    }

    @override
    Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch(config.id) {
            case Maths.ID: {
                Maths casted = config as Maths;
                DataTypeBase processor;
                switch(casted.op) {
                    case Operation.ADD: {
                        DataAttributes newAttrs= attributes.dataProcessorCopySize(4);
                        processor = casted.rhs < 0 ? new SFloatData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, newAttrs,input: this) :
                                dataProcessorCopy(this, newAttrs);
                        break;
                    }
                    case Operation.MULTIPLY: {
                        DataAttributes newAttrs= attributes.dataProcessorCopySize(casted.rhs.abs() < 1 ? attributes.sizes[0] : 4);
                        processor = casted.rhs < 0 ? new SFloatData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, newAttrs,input: this) :
                                dataProcessorCopy(this, newAttrs);
                        break;
                    }
                    case Operation.DIVIDE: {
                        DataAttributes newAttrs = attributes.dataProcessorCopySize(casted.rhs.abs() < 1 ? 4 : attributes.sizes[0]);
                        processor = casted.rhs < 0 ? new SFloatData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, newAttrs,input: this) :
                                dataProcessorCopy(this, newAttrs);
                        break;
                    }
                    case Operation.SUBTRACT:
                        processor = new SFloatData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes.dataProcessorCopySigned(true),input: this);
                        break;
                    case Operation.ABS_VALUE:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySigned(false));
                        break;
                    default:
                        processor = null;
                        break;
                }

                if (processor != null) {
                    return Tuple2(processor, null);
                }
                break;
            }
            case Differential.ID: {
                Differential casted =  config as Differential;
                if (casted.mode == DifferentialOutput.DIFFERENCE) {
                    return Tuple2(new SFloatData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes.dataProcessorCopySigned(true),input: this), null);
                }
            }
        }
        return super.dataProcessorTransform(config, dpModule);
    }


}
