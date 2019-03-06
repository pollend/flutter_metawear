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


enum FilterMode {
    OSR4,
    OSR2,
    NORMAL
}
/**
 * Operating frequencies of the BMI160 accelerometer
 * @author Eric Tsai
 */
class OutputDataRate {


    /** Frequency represented as a float value */
    final double frequency;
    const OutputDataRate._(this.frequency);

    /** 0.78125 Hz */
    static const ODR_0_78125_HZ = OutputDataRate._(0.78125);
    /** 1.5625 Hz */
    static const ODR_1_5625_HZ = OutputDataRate._(1.5625);
    /** 3.125 Hz */
    static const ODR_3_125_HZ= OutputDataRate._(3.125);
    /** 6.25 Hz */
    static const ODR_6_25_HZ= OutputDataRate._(6.25);
    /** 12.5 Hz */
    static const ODR_12_5_HZ= OutputDataRate._(12.5);
    /** 25 Hz */
    static const ODR_25_HZ= OutputDataRate._(25);
    /** 50 Hz */
    static const ODR_50_HZ= OutputDataRate._(50);
    /** 100 Hz */
    static const ODR_100_HZ= OutputDataRate._(100);
    /** 200 Hz */
    static const ODR_200_HZ= OutputDataRate._(200);
    /** 400 Hz */
    static const ODR_400_HZ= OutputDataRate._(400);
    /** 800 Hz */
    static const ODR_800_HZ= OutputDataRate._(800);
    /** 1600 Hz */
    static const ODR_1600_HZ= OutputDataRate._(1600);

    static List<OutputDataRate> _entries = [ODR_0_78125_HZ,ODR_1_5625_HZ,ODR_3_125_HZ,ODR_6_25_HZ,ODR_12_5_HZ,ODR_25_HZ,ODR_50_HZ,ODR_100_HZ,ODR_200_HZ,
    ODR_400_HZ,ODR_800_HZ,ODR_1600_HZ];

    static List<double> get frequences{
        return _entries.map((e) => e.frequency);
    }
}

/**
 * Accelerometer configuration editor specific to the BMI160 accelerometer
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
ConfigEditor range(AccRange fsr);
/**
 * Set the filter mode.  This parameter is ignored if the data rate is less than 12.5Hz
 * @param mode New filter mode
 * @return Calling object
 */
ConfigEditor filter(FilterMode mode);
}

/**
 * Extension of the {@link AccelerometerBosch} interface providing finer control of the BMI160 accelerometer features
 * @author Eric Tsai
 */
abstract class AccelerometerBmi160 extends AccelerometerBosch {


    /**
     * Configure the BMI160 accelerometer
     * @return Editor object specific to the BMI160 accelerometer
     */
    @Override
    ConfigEditor configure();

    /**
     * Operation modes for the step detector
     * @author Eric Tsai
     */
    enum StepDetectorMode {
        /** Default mode with a balance between false positives and false negatives */
        NORMAL,
        /** Mode for light weighted persons that gives few false negatives but eventually more false positives */
        SENSITIVE,
        /** Gives few false positives but eventually more false negatives */
        ROBUST
    }
    /**
     * Configuration editor for the step detection algorithm
     * @author Eric Tsai
     */
    interface StepConfigEditor extends ConfigEditorBase {
        /**
         * Set the operational mode of the step detector balancing sensitivity and robustness.
         * @param mode    Detector sensitivity
         * @return Calling object
         */
        StepConfigEditor mode(StepDetectorMode mode);
        /**
         * Write the configuration to the sensor
         */
        void commit();
    }
    /**
     * Interrupt driven step detection where each detected step triggers a data interrupt.  This data producer
     * cannot be used in conjunction with the {@link StepCounterDataProducer} interface.
     * @author Eric Tsai
     */
    interface StepDetectorDataProducer extends AsyncDataProducer, Configurable<StepConfigEditor> { }
    /**
     * Get an implementation of the StepDetectorDataProducer interface
     * @return StepDetectorDataProducer object
     */
    StepDetectorDataProducer stepDetector();
    /**
     * Accumulates the number of detected steps in a counter that will send its current value on request.  This
     * data producer cannot be used in conjunction with the {@link StepDetectorDataProducer} interface.
     * @author Eric Tsai
     */
    interface StepCounterDataProducer extends ForcedDataProducer, Configurable<StepConfigEditor> {
        /**
         * Reset the internal step counter
         */
        void reset();
    }
    /**
     * Get an implementation of the StepCounterDataProducer interface
     * @return StepCounterDataProducer object
     */
    StepCounterDataProducer stepCounter();

    /**
     * Enumeration of hold times for flat detection
     * @author Eric Tsai
     */
    enum FlatHoldTime {
        /** 0 milliseconds */
        FHT_0_MS(0),
        /** 640 milliseconds */
        FHT_640_MS(640),
        /** 1280 milliseconds */
        FHT_1280_MS(1280),
        /** 2560 milliseconds */
        FHT_2560_MS(2560);

        /** Delays represented as a float value */
        public final float delay;

        FlatHoldTime(float delay) {
            this.delay = delay;
        }

        public static float[] delays() {
            FlatHoldTime[] values= values();
            float[] delayValues= new float[values.length];
            for(byte i= 0; i < delayValues.length; i++) {
                delayValues[i]= values[i].delay;
            }

            return delayValues;
        }
    }

    /**
     * Configuration editor specific to BMI160 flat detection
     * @author Eric Tsai
     */
    interface FlatConfigEditor extends AccelerometerBosch.FlatConfigEditor<FlatConfigEditor> {
        FlatConfigEditor holdTime(FlatHoldTime time);
    }
    /**
     * Extension of the {@link AccelerometerBosch.FlatDataProducer} interface providing
     * configuration options specific to the BMI160 accelerometer
     * @author Eric Tsai
     */
    interface FlatDataProducer extends AccelerometerBosch.FlatDataProducer {
        /**
         * Configure the flat detection algorithm
         * @return BMI160 specific configuration editor object
         */
        @Override
        FlatConfigEditor configure();
    }
    /**
     * Get an implementation of the BMI160 specific FlatDataProducer interface
     * @return FlatDataProducer object
     */
    @Override
    FlatDataProducer flat();

    /**
     * Skip times available for significant motion detection
     * @author Eric Tsai
     */
    enum SkipTime {
        /** 1.5s */
        ST_1_5_S,
        /** 3s */
        ST_3_S,
        /** 6s */
        ST_6_S,
        /** 12s */
        ST_12_S
    }
    /**
     * Proof times available for significant motion detection
     * @author Eric Tsai
     */
    enum ProofTime {
        /** 0.25s */
        PT_0_25_S,
        /** 0.5s */
        PT_0_5_S,
        /** 1s */
        PT_1_S,
        /** 2s */
        PT_2_S
    }
    /**
     * Configuration editor for BMI160 significant motion detection
     * @author Eric Tsai
     */
    interface SignificantMotionConfigEditor extends ConfigEditorBase {
        /**
         * Set the skip time
         * @param time    Number of seconds to sleep after movement is detected
         * @return Calling object
         */
        SignificantMotionConfigEditor skipTime(SkipTime time);
        /**
         * Set the proof time
         * @param time    Number of seconds that movement must still be detected after the skip time passed
         * @return Calling object
         */
        SignificantMotionConfigEditor proofTime(ProofTime time);
    }
    /**
     * Detects when motion occurs due to a change in location.  Examples of this include walking or being in a moving vehicle.
     * Actions that do not trigger significant motion include standing stationary or movement from vibrational sources such
     * as a washing machine.
     * @author Eric Tsai
     */
    interface SignificantMotionDataProducer extends MotionDetection, AsyncDataProducer, Configurable<SignificantMotionConfigEditor> { }
}
