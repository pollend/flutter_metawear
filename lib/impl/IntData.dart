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
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';

import 'package:tuple/tuple.dart';

class _DataPrivate extends DataPrivate{

  Uint8List _data;
  _DataPrivate(this._data,DateTime timestamp, Uint8List dataBytes, dynamic apply(Type target)) : super(timestamp, dataBytes, apply);

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

  IntData._(DataTypeBase input, ModuleType module, int register, int id,
      DataAttributes attributes)
      : super(module, register, attributes, id: id);

  IntData(DataTypeBase input, ModuleType module, int register, DataAttributes attributes)
      : super(module, register, attributes, input: input);


  @override
  DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id,
      DataAttributes attributes) {
    return IntData._(input, module, register, id, attributes);
  }

  @override
  num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
    return value;
  }

  @override
  Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, DateTime timestamp, dynamic apply(Type target)) {
    final Uint8List buffer = Util.bytesToSIntBuffer(logData, data, attributes);

    return _DataPrivate(buffer, timestamp, data, apply);
  }

  @override
  Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(
      DataProcessorConfig config, DataProcessorImpl dpModule) {
    switch (config.id) {
      case Maths.ID:
        {
          Maths casted = config as Maths;
          switch (casted.op) {
            case Operation.ABS_VALUE:
              return Tuple2(new UintData(
                  ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                  attributes.dataProcessorCopySigned(false), input: this),
                  null);
            default:
          }
          break;
        }
    }
    return super.dataProcessorTransform(config, dpModule);
  }
}
