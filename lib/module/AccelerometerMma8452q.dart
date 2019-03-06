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

import 'package:collection/collection.dart';
import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/ConfigEditorBase.dart';
import 'package:flutter_metawear/Configurable.dart';
import 'package:flutter_metawear/data/CartesianAxis.dart';
import 'package:flutter_metawear/data/Sign.dart';
import 'package:flutter_metawear/data/Sign.dart';
import 'package:flutter_metawear/data/TapType.dart';
import 'package:flutter_metawear/module/Accelerometer.dart' as Accelerometer;
import 'package:flutter_metawear/module/AccelerometerBosch.dart';
import 'package:quiver/core.dart';
import 'package:sprintf/sprintf.dart';

/**
 * Available data rates for the MMA8452Q accelerometer
 * @author Eric Tsai
 */
class OutputDataRate {

    final double frequency;

    const OutputDataRate._(this.frequency);

    /** 800Hz */
    static const ODR_800_HZ = const OutputDataRate._(800.0);
    /** 400Hz */
    static const ODR_400_HZ = const OutputDataRate._(400.0);
    /** 200Hz */
    static const ODR_200_HZ = const OutputDataRate._(200.0);
    /** 100Hz */
    static const ODR_100_HZ = const OutputDataRate._(100.0);
    /** 50Hz */
    static const ODR_50_HZ = const OutputDataRate._(50.0);
    /** 12.5Hz */
    static const ODR_12_5_HZ = const OutputDataRate._(12.5);
    /** 6.25Hz */
    static const ODR_6_25_HZ = const OutputDataRate._(6.25);
    /** 1.56Hz */
    static const ODR_1_56_HZ = const OutputDataRate._(1.56);

    static List<OutputDataRate> _entires = [
        ODR_800_HZ,
        ODR_400_HZ,
        ODR_200_HZ,
        ODR_100_HZ,
        ODR_50_HZ,
        ODR_12_5_HZ,
        ODR_6_25_HZ,
        ODR_1_56_HZ
    ];


    static List<double>  get frequencies {
        return _entires.map((f) => f.frequency);
    }
}
/**
 * Available data ranges for the MMA8452Q accelerometer
 * @author Eric Tsai
 */
class FullScaleRange {

    final double range;

    const FullScaleRange._(this.range);

    /** +/-2g */
    static const FSR_2G = FullScaleRange._(2.0);

    /** +/-4g */
    static const FSR_4G = FullScaleRange._(4.0);

    /** +/-8g */
    static const FSR_8G = FullScaleRange._(8.0);

    static List<FullScaleRange> _entires = [
        FSR_2G, FSR_4G, FSR_8G
    ];

    static List<double> ranges() {
        return _entires.map((f) => f.range);
    }
}
/**
 * Available oversampling modes on the MMA8452Q sensor
 * @author Eric Tsai
 */
enum Oversampling {
    NORMAL,
    LOW_NOISE_LOW_POWER,
    HIGH_RES,
    LOW_POWER
}
/**
 * Available data rates when the sensor is in sleep mode
 * @author Eric Tsai
 */
enum SleepModeRate {
    /** 50Hz */
    SMR_50_HZ,
    /** 12.5Hz */
    SMR_12_5_HZ,
    /** 6.25Hz */
    SMR_6_25_HZ,
    /** 1.56Hz */
    SMR_1_56_HZ
}

class SleepMode{
    final SleepModeRate rate;
    final int timeout;
    final Oversampling osMode;

  SleepMode(this.rate, this.timeout, this.osMode);

}

/**
 * Accelerometer configuration editor specific to the MMA8452Q accelerometer
 * @author Eric Tsai
 */
abstract class ConfigEditor implements Accelerometer.ConfigEditor<ConfigEditor> {
    /**
     * Sets the output data rate
     * @param odr    How frequently data is measured
     * @return Calling object
     */
    ConfigEditor odr(OutputDataRate odr);

    /**
     * Sets the data range
     * @param fsr    Range of the measured acceleration
     * @return Calling object
     */
    ConfigEditor range(FullScaleRange fsr);

    /**
     * Enables use of the high pass filter when measuring acceleration, closest valid frequency will be used.
     * This setting only affects the acceleration data from the {@link AccelerationDataProducer} interface.
     * @param cutoff    HPF cutoff frequency for removing the offset and slower changing acceleration data, between
     *                  [0.031Hz, 16Hz]
     * @return Calling object
     */
    ConfigEditor enableHighPassFilter(double cutoff);

    /**
     * Enables low pass filter for the tap detection algorithm
     * @return Calling Object
     */
    ConfigEditor enableTapLowPassFilter();

    /**
     * Sets the oversampling mode when the sensor is active
     * @param osMode    New oversampling mode
     * @return Calling object
     */
    ConfigEditor oversampling(Oversampling osMode);

    /**
     * Variant of {@link #enableAutoSleep()} that lets users configure the auto sleep settings to their use-case
     * @param rate       Output data rate when in sleep mode
     * @param timeout    How long to idle in active mode before switching to sleep mode, in milliseconds
     * @param osMode     Oversampling mode to use when in sleep mode
     * @return Calling object
     */
    ConfigEditor enableAutoSleep([SleepMode mode]);

    /**
     * Enables the autosleep feature where the sensor transitions between different sampling rates depending on
     * the frequency of interrupts
     * @return Calling object
     */
//    ConfigEditor enableAutoSleep();
}

/**
 * Configuration editor for the orientation detection algorithm
 * @author Eric Tsai
 */
abstract class OrientationConfigEditor extends ConfigEditorBase {
    /**
     * Sets the time for which the sensor's orientation must remain in the new position before a position
     * change is triggered.  This is used to filter out false positives from shaky hands or other small vibrations
     * @param delay    How long the sensor must remain in the new position, in milliseconds
     * @return Calling object
     */
    OrientationConfigEditor delay(int delay);
}

/**
 * On-board algorithm that detects changes in the sensor's orientation
 * @author Eric Tsai
 */
abstract class OrientationDataProducer with AsyncDataProducer implements Configurable<OrientationConfigEditor> { }


/**
 * Wrapper class encapsulating free fall, motion, and shake interrupts from the MMA8452Q
 * @author Eric Tsai
 */
class Movement {
    final List<bool> thresholds;
    final List<Sign> polarities;

    /**
     * Create a Movement object
     * @param thresholds    Threshold information for XYZ axis in that order
     * @param polarities    Directional information for XYZ axes in that order
     */
    Movement(this.thresholds, this.polarities);

    /**
     * Check if acceleration is greater than the threshold on that axis
     * @param axis    Axis to lookup
     * @return True if it is greater, false otherwise
     */
    bool exceedsThreshold(CartesianAxis axis) {
        return thresholds[axis.index];
    }

    /**
     * Check the polarity (directional) information of the axis
     * @param axis    Axis to lookup
     * @return {@link Sign#POSITIVE} if event was positive g, {@link Sign#NEGATIVE} if negative g
     */
    Sign polarity(CartesianAxis axis) {
        return polarities[axis.index];
    }

    @override
    String toString() =>
        sprintf(
            "{xExceedsThs: %s, xPolarity: %s, yExceedsThs: %s, yPolarity: %s, zExceedsThs: %s, zPolarity: %s}",
            [
                exceedsThreshold(CartesianAxis.X), polarity(CartesianAxis.X),
                exceedsThreshold(CartesianAxis.Y), polarity(CartesianAxis.Y),
                exceedsThreshold(CartesianAxis.Z), polarity(CartesianAxis.Z)
            ]);

    @override
    bool operator ==(other) =>
        other is Movement &&
            ListEquality().equals(thresholds, other.thresholds) &&
            ListEquality().equals(polarities, other.polarities);

    @override
    int get hashCode => hash2(hashObjects(thresholds), hashObjects(polarities));


}
/**
 * Configuration editor for the shake detection algorithm
 * @author Eric Tsai
 */
abstract class ShakeConfigEditor extends ConfigEditorBase {
    /**
     * Set the axis to detect shaking motion
     * @param axis    Axis to detect shaking
     * @return Calling object
     */
    ShakeConfigEditor axis(CartesianAxis axis);

    /**
     * Set the threshold that the high-pass filtered acceleration must exceed to trigger an interrupt
     * @param threshold    Threshold limit, in g's
     * @return Calling object
     */
    ShakeConfigEditor threshold(double threshold);

    /**
     * Set the minimum amount of time that continuous high-pass filtered acceleration exceeds the threshold
     * @param duration    Duration for the condition to be met, in ms
     * @return Calling object
     */
    ShakeConfigEditor duration(int duration);
}

/**
 * On-board algorithm that detects when the sensor is shaken
 * @author Eric Tsai
 */
abstract class ShakeDataProducer with AsyncDataProducer implements Configurable<ShakeConfigEditor> { }


/**
 * Configuration editor for the tap detection algorithm
 * @author Eric Tsai
 */
abstract class TapConfigEditor extends ConfigEditorBase {
    /**
     * Enable double tap detection
     * @return Calling object
     */
    TapConfigEditor enableDoubleTap();

    /**
     * Enable single tap detection
     * @return Calling object
     */
    TapConfigEditor enableSingleTap();

    /**
     * Set the wait time between the end of the 1st shock and when the 2nd shock can be detected
     * @param latency    New latency time, in milliseconds
     * @return Calling object
     */
    TapConfigEditor latency(int latency);

    /**
     * Set the time in which a second shock must begin after the latency expires
     * @param window    New window time, in milliseconds
     * @return Calling object
     */
    TapConfigEditor window(int window);

    /**
     * Set the axis to detect tapping on
     * @param axis    Axis to detect tapping
     * @return Calling object
     */
    TapConfigEditor axis(CartesianAxis axis);

    /**
     * Set the threshold that begins the tap detection procedure
     * @param threshold    Threshold limit, in units of g
     * @return Calling object
     */
    TapConfigEditor threshold(double threshold);

    /**
     * Set the max time interval between the measured acceleration exceeding the threshold then falling
     * below the threshold.
     * @param interval    Pulse time interval, in ms
     * @return Calling object
     */
    TapConfigEditor interval(int interval);
}

/**
 * On-board algorithm that detects taps
 * @author Eric Tsai
 */
abstract class TapDataProducer with AsyncDataProducer implements Configurable<TapConfigEditor> { }

/**
 * Wrapper class encapsulating tap data from the MMA8452Q accelerometer
 * @author Eric Tsai
 */
class Tap {
    final List<bool> actives;
    final List<Sign> polarities;

    /** Type of tap detected */
    final TapType type;

    /**
     * Creates a Tap object
     * @param active        Interrupt information for XYZ axes in that order
     * @param polarities    Directional information for XYZ axes in that order
     * @param type          Type of tap detected
     */
    Tap(this.actives, this.polarities, this.type);


    /**
     * Check if the axis triggered the tap interrupt
     * @param axis    Axis to lookup
     * @return True if axis triggered the interrupt, false otherwise
     */
    bool active(CartesianAxis axis) {
        return actives[axis.index];
    }

    /**
     * Check the polarity (directional) information of the axis
     * @param axis    Axis to lookup
     * @return {@link Sign#POSITIVE} if event was positive g, {@link Sign#NEGATIVE} if negative g
     */
    Sign polarity(CartesianAxis axis) {
        return polarities[axis.index];
    }

    @override
    String toString() =>
        sprintf(
            "{type: %s, xActive: %s, xPolarity: %s, yActive: %s, yPolarity: %s, zActive: %s, zPolarity: %s}",
            [ active(CartesianAxis.X), polarity(CartesianAxis.X),
            active(CartesianAxis.Y), polarity(CartesianAxis.Y),
            active(CartesianAxis.Z), polarity(CartesianAxis.Z)
            ]);

    @override
    bool operator ==(other) =>
        other is Tap && ListEquality().equals(this.actives, other.actives) &&
            ListEquality().equals(this.polarities, other.polarities);

    @override
    int get hashCode =>
        hash3(hashObjects(polarities), hashObjects(actives), type);

}

/**
 * Configuration editor for the movement detection algorithm
 * @author Eric Tsai
 */
abstract class MovementConfigEditor extends ConfigEditorBase {
    /**
     * Set the axes to be detected for movement
     * @param axes    Axes to detect movement
     * @return Calling object
     */
    MovementConfigEditor axes(List<CartesianAxis> axes);
    /**
     * Set the threshold for movement detection
     * @param threshold    Threshold limit, in units of g
     * @return Calling object
     */
    MovementConfigEditor threshold(double threshold);
    /**
     * Set the minimum amount of time that continuous measured acceleration matches the threshold condition
     * @param duration    Duration for the condition to be met, in ms
     * @return Calling object
     */
    MovementConfigEditor duration(int duration);
}

/**
 * On-board algorithm that detects sensor movement.  The movement algorithm can detect either
 * free fall (measured acceleration less than threshold) or general motion (measured acceleration greater
 * than threshold) but not both simultaneously
 * @author Eric Tsai
 */
abstract class MovementDataProducer with AsyncDataProducer implements Configurable<MovementConfigEditor> { }

/**
 * Extension of the {@link Accelerometer} interface providing finer control of the MMA8452Q accelerometer
 * @author Eric Tsai
 */
abstract class AccelerometerMma8452q implements Accelerometer.Accelerometer{
    
    /**
     * Configure the MMA8452Q accelerometer
     * @return Editor object specific to the MMA8452Q accelerometer
     */
    @override
    ConfigEditor configure();
    /**
     * Get an implementation of the OrientationDataProducer interface
     * @return OrientationDataProducer object
     */
    OrientationDataProducer orientation();


    /**
     * Get an implementation of the ShakeDataProducer interface
     * @return ShakeDataProducer object
     */
    ShakeDataProducer shake();

   
    
    /**
     * Get an implementation of the TapDataProducer interface
     * @return TapDataProducer object
     */
    TapDataProducer tap();

   

    /**
     * Get an implementation of the MovementDataProducer interface for free fall detection
     * @return MovementDataProducer object for free fall detection
     */
    MovementDataProducer freeFall();
    /**
     * Get an implementation of the MovementDataProducer interface for motion detection
     * @return MovementDataProducer object for motion detection
     */
    MovementDataProducer motion();
}
