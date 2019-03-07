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
import 'dart:ui';

import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:sprintf/sprintf.dart';

abstract class ClassToObject {
    Object apply(Type clazz);
}


/**
 * Created by etsai on 9/4/16.
 */
abstract class DataPrivate implements Data {

    final DateTime _timestamp;
    final Uint8List _dataBytes;
    final ClassToObject _mapper;

    DataPrivate(this._timestamp, this._dataBytes, this._mapper);

    @override
    DateTime timestamp() {

        return _timestamp;
    }

    @override
    String formattedTimestamp() {
        return timestamp().toIso8601String();
//        return sprintf("%tY-%<tm-%<tdT%<tH:%<tM:%<tS.%<tL", [timestamp().toIso8601String()]);
    }

    @override
  double scale() => 1.0;

    @override
  Uint8List bytes() => _dataBytes;

    @override
    T value<T>(Type clazz){
        throw CastError();
    }

    T extra<T>(Type clazz){
        Object value;
        if (_mapper == null || (value = _mapper.apply(clazz)) == null) {
            throw CastError();
        }
        return value as T;
    }

//    @override
//    float scale() {
//        return 1.0;
//    }
//
//    @override
//   Uint8List bytes() {
//        return _dataBytes;
//    }
//
//    @override
//    public <T> T value(Class<T> clazz) {
//        throw new ClassCastException(String.format(Locale.US, "Invalid input class: \'%s\'", clazz.toString()));
//    }
//
//    @override
//    public <T> T extra(Class<T> clazz) {
//        Object value;
//        if (mapper == null || (value = mapper.apply(clazz)) == null) {
//            throw new ClassCastException(String.format(Locale.US, "Invalid input class: \'%s\'", clazz.toString()));
//        }
//        return clazz.cast(value);
//    }
//
//    @override
//    public String toString() {
//        return String.format(Locale.US, "{timestamp: %s, data: %s}", formattedTimestamp(), Util.arrayToHexString(bytes()));
//    }

@override
  String toString() => sprintf("{timestamp: %s, data: %s}",[formattedTimestamp(),Util.arrayToHexString(bytes())]);
}
