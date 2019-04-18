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

import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/ConfigEditorBase.dart';
import 'package:flutter_metawear/Configurable.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';

enum FilterMode {
    OSR4,
    OSR2,
    NORMAL
}
/**
 * Operating frequency of the gyro
 * @author Eric Tsai
 */
class OutputDataRate {
    final int bitmask;

    const OutputDataRate._(this.bitmask);

    // 25Hz
    static const ODR_25_HZ = const OutputDataRate._(0x06);
    /** 50Hz */
    static const ODR_50_HZ = const OutputDataRate._(0x07);
    /** 100Hz */
    static const ODR_100_HZ = const OutputDataRate._(0x08);
    /** 200Hz */
    static const ODR_200_HZ = const OutputDataRate._(0x09);
    /** 400Hz */
    static const ODR_400_HZ = const OutputDataRate._(0x0a);
    /** 800Hz */
    static const ODR_800_HZ = const OutputDataRate._(0x0b);
    /** 1600Hz */
    static const ODR_1600_HZ = const OutputDataRate._(0x0c);
    /** 3200Hz */
    static const ODR_3200_HZ = const OutputDataRate._(0x0d);

}

/**
 * Supported angular rate measurement range
 * @author Eric Tsai
 */
class Range {
    final double scale;
    final int bitmask;

    const Range._(this.scale, this.bitmask);

    /** +/- 2000 degrees / second */
    static const FSR_2000 = Range._(16.4, 0x00);

    /** +/- 1000 degrees / second */
    static const FSR_1000 = Range._(32.8, 0x01);

    /** +/- 500 degrees / second */
    static const FSR_500 = Range._(65.6, 0x02);

    /** +/- 250 degrees / second */
    static const FSR_250 = Range._(131.2, 0x03);

    /** +/- 125 degrees / second */
    static const FSR_125 = Range._(262.4, 0x04);


    static final Map<int, Range> _bitMaskToRanges = {
        FSR_2000.bitmask: FSR_2000,
        FSR_1000.bitmask: FSR_1000,
        FSR_500.bitmask: FSR_500,
        FSR_250.bitmask: FSR_250,
        FSR_125.bitmask: FSR_125
    };

    static List<Range> get values => [FSR_2000, FSR_1000, FSR_500, FSR_250, FSR_125];

    static Range bitMaskToRange(int mask) {
        return _bitMaskToRanges[mask];
    }

}

/**
 * Interface to configure parameters for measuring angular velocity
 * @author Eric Tsai
 */
abstract class ConfigEditor extends ConfigEditorBase {
    /**
     * Set the measurement range
     * @param range    New range to use
     * @return Calling object
     */
    ConfigEditor range(Range range);
    /**
     * Set the output date rate
     * @param odr    New output data rate to use
     * @return Calling object
     */
    ConfigEditor odr(OutputDataRate odr);
    /**
     * Set the filter mode
     * @param mode New filter mode
     * @return Calling object
     */
    ConfigEditor filter(FilterMode mode);
}

/**
 * Reports measured angular velocity values from the gyro.  Combined XYZ data is represented as an
 * {@link AngularVelocity} object while split data is interpreted as a float.
 * @author Eric Tsai
 */
abstract class AngularVelocityDataProducer extends AsyncDataProducer {
    /**
     * Get the name for x-axis data
     * @return X-axis data name
     */
    String xAxisName();
    /**
     * Get the name for y-axis data
     * @return Y-axis data name
     */
    String yAxisName();
    /**
     * Get the name for z-axis data
     * @return Z-axis data name
     */
    String zAxisName();
}

/**
 * Sensor on the BMI160 IMU measuring angular velocity
 * @author Eric Tsai
 */
abstract class GyroBmi160 extends Module implements Configurable<ConfigEditor> {

    /**
     * Pulls the current gyro output data rate and data range from the sensor
     * @return Task that is completed when the settings are received
     */
    Future<void> pullConfigAsync();

    /**
     * Get an implementation of the AngularVelocityDataProducer interface
     * @return AngularVelocityDataProducer object
     */
    AngularVelocityDataProducer angularVelocity();
    /**
     * Variant of angular velocity data that packs multiple data samples into 1 BLE packet to increase the
     * data throughput.  Only streaming is supported for this data producer.
     * @return Object representing packed acceleration data
     */
    AsyncDataProducer packedAngularVelocity();

    /**
     * Starts the gyo
     */
    void start();
    /**
     * Stops the gyo
     */
    void stop();
}
