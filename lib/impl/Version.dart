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

import 'package:sprintf/sprintf.dart';

/**
 * Created by etsai on 9/5/16.
 */
class Version implements Comparable<Version> {
    static final RegExp VERSION_STRING_PATTERN = RegExp(
        "(\\d+)\\.(\\d+)\\.(\\d+)");

//    static final long serialVersionUID = -6928626294821091652L;

    final int major;
    final int minor;
    final int step;

    Version(this.major, this.minor, this.step);

    factory Version.fromString(String versionString){
        Match matches = VERSION_STRING_PATTERN.firstMatch(versionString);

        if (matches == null) {
            throw new Exception(
                "Version string: $versionString does not match pattern X.Y.Z");
        }
        int major = int.parse(matches.group(1));
        int minor = int.parse(matches.group(2));
        int step = int.parse(matches.group(3));

        return Version(major, minor, step);
    }

    int weightedCompare(int left, int right) {
        if (left < right) {
            return -1;
        } else if (left > right) {
            return 1;
        }
        return 0;
    }

    @override
    int compareTo(Version other) {
        int sum = 4 * weightedCompare(major, other.major) +
            2 * weightedCompare(minor, other.minor) +
            weightedCompare(step, other.step);
        if (sum < 0) {
            return -1;
        } else if (sum > 0) {
            return 1;
        }
        return 0;
    }



    @override
    String toString() {
        return sprintf("%d.%d.%d", [major, minor, step]);
    }

}
