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


import 'dart:core';

import 'dart:typed_data';

/**
 * Created by etsai on 9/4/16.
 */
class DataAttributes {
//    private static final long serialVersionUID = 236031852609753664L;

    final Uint8List sizes;
    final int copies;
    final int offset;
    final bool signed;

    DataAttributes(this.sizes, this.copies, this.offset, this.signed);


    DataAttributes dataProcessorCopy() {
        Uint8List copy = Uint8List.fromList(sizes);
        return new DataAttributes(copy, copies, 0, signed);
    }

    DataAttributes dataProcessorCopySize(int newSize) {
        Uint8List copy = Uint8List(sizes.length);
        copy.fillRange(0, copy.length, newSize);
        return new DataAttributes(copy, copies, 0, signed);
    }

    DataAttributes dataProcessorCopySigned(bool newSigned) {
        Uint8List copy = Uint8List.fromList(sizes);
        return new DataAttributes(copy, copies, 0, newSigned);
    }

    DataAttributes dataProcessorCopyCopies(int newCopies) {
        Uint8List copy = Uint8List.fromList(sizes);
        return new DataAttributes(copy, newCopies, 0, signed);
    }

    int length() {
        return (unitLength() * copies);
    }

    int unitLength() {
        int sum = 0;
        for (int elem in sizes) {
            sum += elem;
        }
        return sum;
    }

    @override
    bool operator ==(other) {
        if (this == other) return true;
        if (other == null || other is DataAttributes) return false;
        DataAttributes that = other as DataAttributes;
        return copies == that.copies && offset == that.offset &&
            signed == that.signed && Arrays.equals(sizes, that.sizes);
    }

    @override
    int get hashCode {
        int result = sizes.hashCode;
        result = 31 * result + copies;
        result = 31 * result + offset;
        result = 31 * result + (signed ? 1 : 0);
        return result;
    }

}
