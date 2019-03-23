/*
 * Copyright 2014-2018 MbientLab Inc. All rights reserved.
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
 *   hello@mbientlab.com.
 */

import 'dart:typed_data';

import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/module/DataProcessor.dart';

class _DataPrivate extends DataPrivate {
    final ArrayData _arrayData;
    final MetaWearBoardPrivate _mwPrivate;
    final List<Data> _unwrappedData;

    _DataPrivate(this._unwrappedData, this._mwPrivate, this._arrayData,
        DateTime timestamp, Uint8List dataBytes, ClassToObject mapper)
        : super(timestamp, dataBytes, mapper);

    @override
    List<Type> types() {
        return [List];
    }

    @override
    double scale() {
        // TODO: implement scale
        return _arrayData.scale(_mwPrivate);
    }

    @override
    T value<T>() {
        if (T is List<Data>) {
            return _unwrappedData as T;
        }
        return super.value<T>();
    }

}

class ArrayData extends DataTypeBase {
    ArrayData(ModuleType module, int register, DataAttributes attributes,
        {int id, DataTypeBase input})
        :super(module, register, attributes, id: id, input: input);

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new ArrayData(
            module, register, attributes, input: input, id: id);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value;
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, ClassToObject mapper) {
        DataProcessorImpl dpModules = mwPrivate.getModules()[DataProcessor];
        Processor fuser = dpModules.activeProcessors[eventConfig[2]];

        while (!(fuser.editor.configObj is Fuser)) {
            fuser = dpModules.activeProcessors[fuser.editor.source.input
                .eventConfig[2]];
        }

        DataTypeBase source = fuser.editor.source.input == null ? fuser.editor
            .source : fuser.editor.source.input;
        int offset = 0;
        final List<Data> unwrappedData = List<Data>(
            fuser.editor.config.length + 1);
        unwrappedData[0] =
            source.createMessage(logData, mwPrivate, data, timestamp, mapper);
        offset += source.attributes.length();

        for (int i = 2; i < fuser.editor.config.length; i++) {
            Processor value = dpModules.activeProcessors[fuser.editor
                .config[i]];
            // buffer state holds the actual data type
            Uint8List portion = Uint8List(value.state.attributes.length());

            portion.setAll(0, data.skip(offset));
            unwrappedData[i - 1] = value.state.createMessage(
                logData, mwPrivate, portion, timestamp, mapper);

            offset += value.state.attributes.length();
            i++;
        }

        return _DataPrivate(
            unwrappedData, mwPrivate, this, timestamp, data, mapper);
    }
}
