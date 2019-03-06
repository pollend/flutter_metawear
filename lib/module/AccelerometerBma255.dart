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


import 'package:flutter_metawear/module/Accelerometer.dart' as Accelerometer;
import 'package:flutter_metawear/module/AccelerometerBosch.dart';

/**
 * Operating frequencies of the accelerometer
 * @author Eric Tsai
 */
class OutputDataRate {
    /** Frequency represented as a float value */
    final double frequency;

    const OutputDataRate._(this.frequency);

    /** 15.62 Hz */
    static const ODR_15_62HZ = const OutputDataRate._(15.62);

    /** 31.26 Hz */
    static const ODR_31_26HZ = const OutputDataRate._(31.26);

    /** 62.5 Hz */
    static const ODR_62_5HZ = const OutputDataRate._(62.5);

    /** 125 Hz */
    static const ODR_125HZ = const OutputDataRate._(125);

    /** 250 Hz */
    static const ODR_250HZ = const OutputDataRate._(250);

    /** 500 Hz */
    static const ODR_500HZ = const OutputDataRate._(500);

    /** 1000 Hz */
    static const ODR_1000HZ = const OutputDataRate._(1000);

    /** 2000 Hz */
    static const ODR_2000HZ = const OutputDataRate._(2000);

    static List<OutputDataRate> _entires = [
        ODR_15_62HZ,
        ODR_31_26HZ,
        ODR_62_5HZ,
        ODR_125HZ,
        ODR_250HZ,
        ODR_500HZ,
        ODR_1000HZ,
        ODR_2000HZ
    ];

    static List<double> frequencies() {
        return _entires.map((f) => f.frequency);
    }
}

/**
 * Enumeration of hold times for flat detection
 * @author Eric Tsai
 */
class FlatHoldTime {
    /** Periods represented as a float value */
    final double delay;

    const FlatHoldTime._(this.delay);

    /** 0 milliseconds */
    static const FHT_0_MS = const FlatHoldTime._(0);

    /** 512 milliseconds */
    static const FHT_512_MS = const FlatHoldTime._(512);

    /** 1024 milliseconds */
    static const FHT_1024_MS = const FlatHoldTime._(1024);

    /** 2048 milliseconds */
    static const FHT_2048_MS = const FlatHoldTime._(2048);

    static List<FlatHoldTime> _entires = [
        FHT_0_MS,
        FHT_512_MS,
        FHT_1024_MS,
        FHT_2048_MS
    ];

    static List<double> delays() {
        return _entires.map((e) => e.delay);
    }
}

/**
 * Accelerometer configuration editor specific to the BMA255 accelerometer
 * @author Eric Tsai
 */
abstract class ConfigEditor extends Accelerometer.ConfigEditor<ConfigEditor> {

    /**
     * Set the output data rate
     * @param odr    New output data rate
     * @return Calling object
     */
    ConfigEditor odr(OutputDataRate odr);

    /**
     * Set the data range
     * @param fsr    New data range
     * @return Calling object
     */
    ConfigEditor rangeForRange(AccRange fsr);
}

/**
 * Extension of the {@link AccelerometerBosch} interface providing finer control of the BMA255 accelerometer
 * @author Eric Tsai
 */
abstract class AccelerometerBma255 extends AccelerometerBosch {

    /**
     * Configure the BMA255 accelerometer
     * @return Editor object specific to the BMA255 accelerometer
     */
    @Override
    ConfigEditor configure();

    /**
     * Configuration editor specific to BMA255 flat detection
     * @author Eric Tsai
     */
    interface FlatConfigEditor extends AccelerometerBosch.FlatConfigEditor<FlatConfigEditor> {
        FlatConfigEditor holdTime(FlatHoldTime time);
    }
    /**
     * Extension of the {@link AccelerometerBosch.FlatDataProducer} interface providing
     * configuration options specific to the BMA255 accelerometer
     * @author Eric Tsai
     */
    interface FlatDataProducer extends AccelerometerBosch.FlatDataProducer {
        /**
         * Configure the flat detection algorithm
         * @return BMA255 specific configuration editor object
         */
        @Override
        FlatConfigEditor configure();
    }
    /**
     * Get an implementation of the BMA255 specific FlatDataProducer interface
     * @return BMA255 specific FlatDataProducer object
     */
    @Override
    FlatDataProducer flat();
}
