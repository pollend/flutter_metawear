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



import 'FloatVector.dart';
import 'package:sprintf/sprintf.dart';

/**
 * Encapsulates Euler angles, values are in degrees
 * @author Eric Tsai
 */
class EulerAngles extends FloatVector {
    static const String DEGS= "\u00B0";

    EulerAngles(double heading, double pitch, double roll, double yaw) : super(heading,pitch,roll,yaw);

    /**
     * Gets the heading angle
     * @return Heading angel
     */
    double heading() {
        return vector[0];
    }
    /**
     * Gets the pitch angle
     * @return Pitch angle
     */
    double pitch() {
        return vector[1];
    }
    /**
     * Gets the roll angle
     * @return Roll angle
     */
    double roll() {
        return vector[2];
    }
    /**
     * Gets the yaw angle
     * @return Yaw angle
     */
    double yaw() {
        return vector[3];
    }

    @override
    String toString() {

        return sprintf("{heading %.3f%s, pitch: %.3f%s, roll: %.3f%s, yaw: %.3f%s}",[
                heading(), DEGS,
                pitch(), DEGS,
                roll(), DEGS,
                yaw(), DEGS]);
    }
}
