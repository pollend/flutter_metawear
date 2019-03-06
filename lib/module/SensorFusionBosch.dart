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

import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/ConfigEditorBase.dart';
import 'package:flutter_metawear/Configurable.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';
import 'package:flutter_metawear/data/Acceleration.dart';
import 'package:flutter_metawear/data/AngularVelocity.dart';
import 'package:flutter_metawear/data/MagneticField.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/SensorFusionBosch.dart';
import 'package:flutter_metawear/module/SensorFusionBosch.dart';
import 'package:sprintf/sprintf.dart';
import 'package:quiver/core.dart';
import 'package:collection/collection.dart';

/**
 * Supported data ranges for accelerometer data
 * @author Eric Tsai
 */
enum AccRange {
    /** +/-2g */
    AR_2G,
    /** +/-4g */
    AR_4G,
    /** +/-8g */
    AR_8G,
    /** +/-16g */
    AR_16G,
}
/**
 * Supported data ranges for gyro data
 * @author Eric Tsai
 */
enum GyroRange {
    /** +/-2000 degs/s */
    GR_2000DPS,
    /** +/-1000 degs/s */
    GR_1000DPS,
    /** +/-500 degs/s */
    GR_500DPS,
    /** +/-250 degs/s */
    GR_250DPS,
}
/**
 * Accuracy of the correct sensor data
 * @author Eric Tsai
 */
enum CalibrationAccuracy {
    UNRELIABLE,
    LOW_ACCURACY,
    MEDIUM_ACCURACY,
    HIGH_ACCURACY
}
/**
 * Available sensor fusion modes
 * @author Eric Tsai
 */
enum Mode {
    SLEEP,
    NDOF,
    IMU_PLUS,
    COMPASS,
    M4G
}


/**
 * Configuration editor for the sensor fusion algorithm
 * @author Eric Tsai
 */
abstract class ConfigEditor extends ConfigEditorBase {
    /**
     * Sets the sensor fusion mode
     * @param mode    New sensor fusion mode
     * @return Calling object
     */
    ConfigEditor mode(Mode mode);

    /**
     * Sets the accelerometer data range
     * @param range    New data range
     * @return Calling object
     */
    ConfigEditor accRange(AccRange range);

    /**
     * Sets the gyro data range
     * @param range    New data range
     * @return Calling object
     */
    ConfigEditor gyroRange(GyroRange range);

    /**
     * Extra configuration settings for the accelerometer
     * @param settings Additional accelerometer settings
     * @return Calling object
     */
    ConfigEditor accExtra(List<Object> settings);

    /**
     * Extra configuration settings for the gyroscope
     * @param settings Additional gyroscope settings
     * @return Calling object
     */
    ConfigEditor gyroExtra(List<Object> settings);
}

/**
 * Handler for processing download updates
 */
abstract class CalibrationStateUpdateHandler {
/**
 * Called when the current calibration state is received
 * @param state     Currentt calibration state
 */
void receivedUpdate(CalibrationState state);
}

/**
 * Tuple wrapping the calibration state of the IMU sensors
 * @author Eric Tsai
 */
class CalibrationState {
    /**
     * Current calibration accuracy for the accelerometer, gyroscope, and magnetometer
     */
    final CalibrationAccuracy accelerometer, gyroscope, magnetometer;

    CalibrationState(this.accelerometer, this.gyroscope, this.magnetometer);

    @override
    bool operator ==(other) {
        return other is CalibrationState &&
            other.magnetometer == this.magnetometer &&
            other.gyroscope == this.gyroscope &&
            this.accelerometer == accelerometer;
    }


    @override
    // TODO: implement hashCode
    int get hashCode =>
        hash3(this.accelerometer.hashCode, this.gyroscope.hashCode,
            this.magnetometer.hashCode);

    @override
    String toString() {
        return sprintf(
            "CalibrationState: {accelerometer: %s, gyroscope: %s, magnetometer: %s}",
            [
                accelerometer.toString(),
                gyroscope.toString(),
                magnetometer.toString()
            ]);
    }

}
/**
 * Container class holding corrected acceleration data, in units of g's
 * @author Eric Tsai
 */
class CorrectedAcceleration extends Acceleration {
    final CalibrationAccuracy accuracy;

    factory CorrectedAcceleration(double x, double y, double z, int index){
        return CorrectedAcceleration._(
            x, y, z, CalibrationAccuracy.values[index]);
    }

    CorrectedAcceleration._(double x, double y, double z, this.accuracy)
        : super(x, y, z);

    @override
    String toString() {
        return sprintf("{x: %.3fg, y: %.3fg, z: %.3fg, accuracy: %s}",
            [x(), y(), z(), accuracy.toString()]);
    }

    @override
    bool operator ==(other) {
        return other is CorrectedAcceleration &&
            other.accuracy == this.accuracy;
    }

    @override
    int get hashCode => hash2(super.hashCode, accuracy);

}

/**
 * Container class holding corrected angular velocity data, in degrees per second
 * @author Eric Tsai
 */
class CorrectedAngularVelocity extends AngularVelocity {
    final CalibrationAccuracy accuracy;

    CorrectedAngularVelocity._(double x, double y, double z, this.accuracy)
        :super(x, y, z);

    factory CorrectedAngularVelocity(double x, double y, double z, int index){
        return CorrectedAngularVelocity._(
            x, y, z, CalibrationAccuracy.values[index]);
    }

    @override
    String toString() =>
        sprintf("{x: %.3f%s, y: %.3f%s, z: %.3f%s, accuracy: %s}", [
            x(), AngularVelocity.DEGS_PER_SEC,
            y(), AngularVelocity.DEGS_PER_SEC,
            z(), AngularVelocity.DEGS_PER_SEC,
        ]);


    @override
    bool operator ==(other) {
        return other is CorrectedAngularVelocity &&
            other.accuracy == this.accuracy;
    }

    @override
    int get hashCode => hash2(super.hashCode, accuracy);
}
/**
 * Container class holding corrected magnetic field strength data, in micro teslas
 * @author Eric Tsai
 */
class CorrectedMagneticField extends MagneticField {
    final CalibrationAccuracy accuracy;

    CorrectedMagneticField._(double x, double y, double z, this.accuracy)
        :super(x, y, z);

    factory CorrectedMagneticField(double x, double y, double z, int index){
        return CorrectedMagneticField._(
            x, y, z, CalibrationAccuracy.values[index]);
    }


    @override
    String toString() =>
        sprintf("{x: %.9fT, y: %.9fT, z: %.9fT, accuracy: %s}",
            [x(), y(), z(), accuracy.toString()]);

    @override
    int get hashCode => hash2(accuracy, super.hashCode);

    @override
    bool operator ==(other) {
        return other is CorrectedMagneticField && this.accuracy == accuracy;
    }

}

/**
 * Tuple class holding the IMU calibration data
 * @author Eric Tsai
 */
class CalibrationData {
    /**
     * Current calibration accuracy values for the accelerometer, gyroscope, and magnetometer respectively
     */
    final Uint8List accelerometer, gyroscope, magnetometer;

    CalibrationData(this.accelerometer, this.gyroscope, this.magnetometer);


    @override
    int get hashCode =>
        hash3(hashObjects(accelerometer), hashObjects(gyroscope),
            hashObjects(magnetometer));

    @override
    bool operator ==(other) {
        return other is CalibrationData &&
            ListEquality().equals(accelerometer, other.accelerometer) &&
            ListEquality().equals(gyroscope, other.gyroscope) &&
            ListEquality().equals(magnetometer, other.magnetometer);
    }

    @override
    String toString() {
        // TODO: implement toString
        return sprintf(
            "CalibrationData: {accelerometer: %s, gyroscope: %s, magnetometer: %s}",
            [
                Util.arrayToHexString(accelerometer),
                Util.arrayToHexString(gyroscope),
                Util.arrayToHexString(magnetometer)
            ]);
    }
}

/**
 * Algorithm combining accelerometer, gyroscope, and magnetometer data for Bosch sensors.  When using
 * sensor fusion, do not configure the accelerometer, gyro, and magnetometer with their respective interface;
 * the algorithm will automatically configure those sensors based on the selected fusion mode.
 * @author Eric Tsai
 */
abstract class SensorFusionBosch implements Module, Configurable<ConfigEditor> {



    /**
     * Get an implementation of the AsyncDataProducer interface for corrected acceleration data,
     * represented by the {@link CorrectedAcceleration} class.
     * @return AsyncDataProducer Object for corrected acceleration data
     */
    AsyncDataProducer correctedAcceleration();
    /**
     * Get an implementation of the AsyncDataProducer interface for corrected angular velocity data,
     * represented by the {@link CorrectedAngularVelocity} class.
     * @return AsyncDataProducer Object for corrected angular velocity data
     */
    AsyncDataProducer correctedAngularVelocity();
    /**
     * Get an implementation of the AsyncDataProducer interface for corrected magnetic field data,
     * represented by the {@link CorrectedMagneticField} class.
     * @return AsyncDataProducer Object for corrected magnetic field data
     */
    AsyncDataProducer correctedMagneticField();
    /**
     * Get an implementation of the AsyncDataProducer interface for quaternion data,
     * represented by the {@link Quaternion} class.
     * @return AsyncDataProducer Object for quaternion data
     */
    AsyncDataProducer quaternion();
    /**
     * Get an implementation of the AsyncDataProducer interface for euler angles,
     * represented by the {@link EulerAngles} class.
     * @return AsyncDataProducer Object for euler angles
     */
    AsyncDataProducer eulerAngles();
    /**
     * Get an implementation of the AsyncDataProducer interface for the acceleration from gravity vector,
     * represented by the {@link Acceleration} class.
     * @return AsyncDataProducer Object for acceleration from gravity
     */
    AsyncDataProducer gravity();
    /**
     * Get an implementation of the AsyncDataProducer interface for linear acceleration,
     * represented by the {@link Acceleration} class.
     * @return AsyncDataProducer Object for linear acceleration
     */
    AsyncDataProducer linearAcceleration();

    /**
     * Start the algorithm
     */
    void start();
    /**
     * Stop the algorithm
     */
    void stop();

    /**
     * Pulls the current sensor fusion configuration from the sensor
     * @return Task that is completed when the settings are received
     */
    Future<void> pullConfigAsync();
    /**
     * Reads the current calibration state from the sensor fusion algorithm.  This function cannot be
     * called until the sensor fusion algorithm is running and is only available on firmware v1.4.1 and newer.
     * @return Task containing the calibration status
     */
    Future<CalibrationState> readCalibrationStateAsync();

    /**
     * Convenience method to continuously poll the calibration state until the required IMUs are in a high accuracy state
     * @param ct                The cancellation token that will be checked before reading the calibration state
     * @param pollingPeriod     How frequently poll the calibration state in milliseconds
     * @param updateHandler     Handler for calibration state updates
     * @return Task containing the calibration data
     */
    Future<CalibrationData> calibrate(CancellationToken ct, long pollingPeriod, CalibrationStateUpdateHandler updateHandler);
    /**
     * Variant of {@link #calibrate(CancellationToken, long, CalibrationStateUpdateHandler)} with polling period set to 1000ms
     * @param ct                The cancellation token that will be checked before reading the calibration state
     * @param updateHandler     Handler for calibration state updates
     * @return @return Task containing the calibration data
     */
    Future<CalibrationData> calibrate(CancellationToken ct, CalibrationStateUpdateHandler updateHandler);
    /**
     * Variant of {@link #calibrate(CancellationToken, long, CalibrationStateUpdateHandler)} with no calibration state updates
     * @param ct                The cancellation token that will be checked before reading the calibration state
     * @param pollingPeriod     How frequently poll the calibration state in milliseconds
     * @return @return Task containing the calibration data
     */
    Future<CalibrationData> calibrate(CancellationToken ct, long pollingPeriod);
    /**
     * Variant of {@link #calibrate(CancellationToken, long, CalibrationStateUpdateHandler)} with polling period set to 1000ms and no calibration state updates
     * @param ct                The cancellation token that will be checked before reading the calibration state
     * @return @return Task containing the calibration data
     */
    Future<CalibrationData> calibrate(CancellationToken ct);
    /**
     * Writes calibration data to the sensor fusion algorithm, only for firmware v1.4.2+.
     * Combine this function with the {@link Macro} module to write the data at boot time
     * @param data      Calibration data returned from the {@link #calibrate(CancellationToken, long, CalibrationStateUpdateHandler) calibrate} function
     */
    void writeCalibrationData(CalibrationData data);
}
