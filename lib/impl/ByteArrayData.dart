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

import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';

class _DataPrivate extends DataPrivate{
    @override
    List<Type> types() {
        return [Uint8List];
    }

    @override
     double scale() {
        return ByteArrayData.this.scale(mwPrivate);
    }

    @override
    public <T> T value(Class<T> clazz) {
        if (clazz.equals(byte[].class)) {
            return clazz.cast(data);
        }
        return super.value(clazz);
    }
}

/**
 * Created by etsai on 9/21/16.
 */
class ByteArrayData extends DataTypeBase {
    ByteArrayData(ModuleType module, int register, DataAttributes attributes) : super(module, register, attributes, ()=>{});



//    ByteArrayData(ModuleType module, int register, DataAttributes attributes,{int id, DataTypeBase input}):

//    ByteArrayData(Module module, byte register, byte id, DataAttributes attributes) {
//        super(module, register, id, attributes);
//    }
//
//    ByteArrayData(DataTypeBase input, Module module, byte register, DataAttributes attributes) {
//        super(input, module, register, attributes);
//    }
//
//    ByteArrayData(DataTypeBase input, Module module, byte register, byte id, DataAttributes attributes) {
//        super(input, module, register, id, attributes);
//    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new ByteArrayData(input, module, register, id, attributes);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, Number value) {
        return value;
    }

    @override
    Data createMessage(boolean logData, final MetaWearBoardPrivate mwPrivate, final byte[] data, final Calendar timestamp, DataPrivate.ClassToObject mapper) {
        return new DataPrivate(timestamp, data, mapper) {
            @override
            public Class<?>[] types() {
                return new Class<?>[] { byte[].class };
            }

            @override
            public float scale() {
                return ByteArrayData.this.scale(mwPrivate);
            }

            @override
            public <T> T value(Class<T> clazz) {
                if (clazz.equals(byte[].class)) {
                    return clazz.cast(data);
                }
                return super.value(clazz);
            }
        };
    }
}
