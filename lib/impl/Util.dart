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


import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:math';
/**
 * Created by etsai on 9/4/16.
 */
class Util {
    static int closestIndex(List<double> values, double key) {
        double smallest = (values[0] - key).abs();
        int place = 0;

        for (int i = 1; i < values.length; i++) {
            double distance = (values[i] - key).abs();
            if (distance < smallest) {
                smallest = distance;
                place = i;
            }
        }

        return place;
    }


    static String arrayToHexString(List<int> value) {
        if (value == null || value.length == 0) {
            return "[]";
        }

        StringBuffer builder= new StringBuffer();
        builder.write(sprintf("[0x%02x", value[0]));
        for(int i= 1; i < value.length; i++) {
            builder.write(sprintf(", 0x%02x", value[i]));
        }
        builder.write("]");

        return builder.toString();
    }

    static Uint8List bytesToSIntBuffer(bool logData, Uint8List data, DataAttributes attributes) {
        Uint8List actual;

        if (logData) {
            actual = Uint8List(min(data.length, attributes.length()));
            actual.setAll(0, data);
        } else {
            actual = Uint8List(min(data.length - attributes.offset, attributes.length()));
            actual.setAll(0, data);
//            System.arraycopy(data, attributes.offset, actual, 0, actual.length);
        }
        return _padByteArray(actual,4,true);//, newSize, signed)ByteBuffer.wrap(Util.padByteArray(actual, 4, true)).order(ByteOrder.LITTLE_ENDIAN);
    }

    static Uint8List bytesToUIntBuffer(bool logData, Uint8List data, DataAttributes attributes) {
        Uint8List actual;

        if (logData) {
            actual = Uint8List(min(data.length, attributes.length()));
            actual.setAll(0, data);
//            System.arraycopy(data, 0, actual, 0, actual.length);
        } else {
            actual = Uint8List(min(data.length - attributes.offset, attributes.length()));
            actual.setAll(attributes.offset, data);
//            System.arraycopy(data, attributes.offset, actual, 0, actual.length);
        }

        return _padByteArray(actual,8,false);//, newSize, signed) ByteBuffer.wrap(Util.padByteArray(actual, 8, false)).order(ByteOrder.LITTLE_ENDIAN);
    }

    static Uint8List _padByteArray(Uint8List input, int newSize, bool signed) {
        if (newSize <= input.length) {
            Uint8List copy = Uint8List(input.length);
            copy.setAll(0, input);
            return copy;
        }

        Uint8List copy= Uint8List(newSize);
        int padByte;
        if (signed && (input[input.length - 1] & 0x80) == 0x80) {
            padByte= 0xff;
        } else {
            padByte= 0;
        }
        copy.fillRange(0, copy.length-1,padByte);
        copy.setAll(0, input);
        return copy;
    }

    static String createProducerChainString(DataTypeBase source, MetaWearBoardPrivate mwPrivate) {
        Queue<DataTypeBase> parents = Queue();
        DataTypeBase current = source;

        do {
            parents.add(current);
            current = current.input;
        } while(current != null);

        StringBuffer builder = StringBuffer();
        bool first = true;
        while(!parents.isEmpty) {
            if (!first) {
                builder.write(":");
            }
            builder.write(DataTypeBase.createUri(parents.removeFirst(), mwPrivate));
            first = false;
        }

        return builder.toString();
    }

    static int clearRead(int value) {
        return (value & 0x3f);
    }
    static int setRead(int value) {
        return (0x80 | value);
    }
    static int setSilentRead(int value) {
        return (0xc0 | value);
    }
}
