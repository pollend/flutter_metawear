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
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/Util.dart';

class _DataPrivate extends DataPrivate{

  Uint8List _data;
  _DataPrivate(this._data,DateTime timestamp, Uint8List dataBytes, ClassToObject mapper) : super(timestamp, dataBytes, mapper);

  @override
  List<Type> types() {
    return [bool,int];
  }

  @override
  T value<T>() {
      if(T is bool || T is int){
          return _data[0] as T;
      }
      return super.value<T>();
  }

}

/**
 * Created by etsai on 9/5/16.
 */
class IntData extends DataTypeBase {

    private IntData(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    IntData(DataTypeBase input, Constant.Module module, byte register, DataAttributes attributes) {
        super(input, module, register, attributes);
    }

    @override
    DataTypeBase copy(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        return new IntData(input, module, register, id, attributes);
    }

    @override
     num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, Number value) {
        return value;
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, DateTime timestamp, ClassToObject mapper) {
        final Uint8List buffer = Util.bytesToSIntBuffer(logData, data, attributes);

        return _DataPrivate(buffer,timestamp,data,mapper);
//        return new DataPrivate(timestamp, data, mapper) {
//            @override
//            public Class<?>[] types() {
//                return new Class<?>[] {Integer.class, Short.class, Byte.class, Boolean.class};
//            }
//
//            @override
//            public <T> T value(Class<T> clazz) {
//                if (clazz == Boolean.class) {
//                    return clazz.cast(buffer.get(0) != 0);
//                }
//                if (clazz == Integer.class) {
//                    return clazz.cast(buffer.getInt(0));
//                }
//                if (clazz == Short.class) {
//                    return clazz.cast(buffer.getShort(0));
//                }
//                if (clazz == Byte.class) {
//                    return clazz.cast(buffer.get(0));
//                }
//                return super.value(clazz);
//            }
//        };
    }

    @override
    Pair<? extends DataTypeBase, ? extends DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch(config.id) {
            case DataProcessorConfig.Maths.ID: {
                DataProcessorConfig.Maths casted = (DataProcessorConfig.Maths) config;
                switch(casted.op) {
                    case ABS_VALUE:
                        return new Pair<>(new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes.dataProcessorCopySigned(false)), null);
                }
                break;
            }
        }
        return super.dataProcessorTransform(config, dpModule);
    }
}
