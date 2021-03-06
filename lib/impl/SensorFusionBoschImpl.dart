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


import 'dart:async';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/data/Acceleration.dart';
import 'package:flutter_metawear/data/EulerAngles.dart';
import 'package:flutter_metawear/data/Quaternion.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/module/SensorFusionBosch.dart';
import 'package:tuple/tuple.dart';
import 'Util.dart';
import 'package:flutter_metawear/module/Accelerometer.dart' as Accelerometer;
import 'package:flutter_metawear/module/AccelerometerBmi160.dart' as AccelerometerBmi160;
import 'package:flutter_metawear/module/GyroBmi160.dart' as GyroBmi160;
import 'package:flutter_metawear/module/MagnetometerBmm150.dart' as MagnetometerBmm150;
import 'package:flutter_metawear/module/AccelerometerBosch.dart' as AccelerometerBosch;

class EulerAngleData extends DataTypeBase {

    EulerAngleData.Default() :super(
        ModuleType.SENSOR_FUSION, SensorFusionBoschImpl.EULER_ANGLES,
        new DataAttributes(Uint8List.fromList([4, 4, 4, 4]), 1, 0, true));


    EulerAngleData(DataTypeBase input, ModuleType module, int register, int id,
        DataAttributes attributes)
        : super(module, register, attributes, input: input, id: id);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new EulerAngleData(input, module, register, id, attributes);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value;
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);

        final List<double> values = [
            buffer.getFloat32(0,Endian.little),
            buffer.getFloat32(4,Endian.little),
            buffer.getFloat32(8,Endian.little),
            buffer.getFloat32(12,Endian.little)
        ];
        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is EulerAngles) {
                return EulerAngles(
                    values[0], values[1], values[2], values[3]) as T;
            } else if (T is List<double>) {
                return values as T;
            }
            throw CastError();
        });
    }

}
class QuaternionData extends DataTypeBase {

    QuaternionData.Default() :super(
        ModuleType.SENSOR_FUSION, SensorFusionBoschImpl.QUATERNION,
        new DataAttributes(Uint8List.fromList([4, 4, 4, 4]), 1, 0, true));


    QuaternionData(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes)
        : super(module, register, attributes, id: id, input: input);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new QuaternionData(input, module, register, id, attributes);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value;
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);

        final List<double> values = [
            buffer.getFloat32(0,Endian.little),
            buffer.getFloat32(4,Endian.little),
            buffer.getFloat32(8,Endian.little),
            buffer.getFloat32(12,Endian.little)
        ];
        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is EulerAngles) {
                return Quaternion(
                    values[0], values[1], values[2], values[3]) as T;
            } else if (T is List<double>) {
                return values as T;
            }
            throw CastError();
        });
    }
}

class AccelerationData extends DataTypeBase {
    static const double MSS_TO_G = 9.80665;

    AccelerationData.Default(int register) : super(
        ModuleType.SENSOR_FUSION, register,
        new DataAttributes(Uint8List.fromList([4, 4, 4]), 1, 0, true));


    AccelerationData(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes)
        : super(module, register, attributes, id: id, input: input);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new AccelerationData(
            input, module, register, id, attributes);
    }

    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value;
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);
        final List<double> values = [
            buffer.getFloat32(0, Endian.little) / MSS_TO_G,
            buffer.getFloat32(4, Endian.little) / MSS_TO_G,
            buffer.getFloat32(8, Endian.little) / MSS_TO_G
        ];

        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is Acceleration) {
                return Acceleration(values[0], values[1], values[2]) as T;
            }
            if (T is List<double>) {
                return values as T;
            }
        });
    }
}


abstract class CorrectedSensorData extends DataTypeBase {

    CorrectedSensorData.Default(int register) : super(
        ModuleType.SENSOR_FUSION, register,
        new DataAttributes(Uint8List.fromList([4, 4, 4, 1]), 1, 0, true));


    CorrectedSensorData(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes)
        : super(module, register, attributes, input: input, id: id);


    @override
    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, value) {
        return value;
    }
}

class CorrectedAccelerationData extends CorrectedSensorData {

    CorrectedAccelerationData.Default()
        : super.Default(SensorFusionBoschImpl.CORRECTED_ACC);


    CorrectedAccelerationData(DataTypeBase input, ModuleType module,
        int register, int id, DataAttributes attributes)
        : super(input, module, register, id, attributes);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new CorrectedAccelerationData(
            input, module, register, id, attributes);
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);
        final CorrectedAcceleration values = CorrectedAcceleration(
            buffer.getFloat32(0, Endian.little) / 1000.0,
            buffer.getFloat32(4, Endian.little) / 1000.0,
            buffer.getFloat32(8, Endian.little) / 1000.0,
            buffer.getInt8(12));

        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is CorrectedAcceleration) {
                return values as T;
            }
            throw CastError();
        });
    }
}
class CorrectedAngularVelocityData extends CorrectedSensorData {

    CorrectedAngularVelocityData.Default()
        : super.Default(SensorFusionBoschImpl.CORRECTED_ROT);

    CorrectedAngularVelocityData(DataTypeBase input, ModuleType module,
        int register, int id, DataAttributes attributes)
        : super(input, module, register, id, attributes);

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new CorrectedAngularVelocityData(
            input, module, register, id, attributes);
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);

        final CorrectedAngularVelocity values = CorrectedAngularVelocity(
            buffer.getFloat32(0, Endian.little),
            buffer.getFloat32(4, Endian.little),
            buffer.getFloat32(8, Endian.little),
            buffer.getInt8(12));

        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is CorrectedAngularVelocity) {
                return values as T;
            }
            throw CastError();
        });
    }
}

class CorrectedMagneticFieldData extends CorrectedSensorData {
    CorrectedMagneticFieldData.Default()
        :super.Default(SensorFusionBoschImpl.CORRECTED_MAG);


    CorrectedMagneticFieldData(DataTypeBase input, ModuleType module,
        int register, int id, DataAttributes attributes)
        : super(input, module, register, id, attributes);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
        int id, DataAttributes attributes) {
        return new CorrectedMagneticFieldData(
            input, module, register, id, attributes);
    }

    @override
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
        Uint8List data, DateTime timestamp, T Function<T>() apply) {
        ByteData buffer = ByteData.view(data.buffer);
        final CorrectedMagneticField values = CorrectedMagneticField(
            buffer.getFloat32(0, Endian.little) / 1000000.0,
            buffer.getFloat32(4, Endian.little) / 1000000.0,
            buffer.getFloat32(8, Endian.little) / 1000000.0,
            buffer.getInt8(12));

        return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
            if (T is CorrectedMagneticField) {
                return values as T;
            }
            throw CastError();
        });
    }
}

class _SensorFusionAsyncDataProducer implements AsyncDataProducer {
    final String producerTag;
    final int mask;
    final SensorFusionBoschImpl _impl;

    _SensorFusionAsyncDataProducer(this._impl, this.producerTag, this.mask);

    @override
    String name() {
        return producerTag;
    }

    @override
    void start() {
        _impl.dataEnableMask |= mask;
    }

    @override
    void stop() {
        _impl.dataEnableMask &= ~mask;
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return _impl.mwPrivate.queueRouteBuilder(builder, producerTag);
    }
}


/**
 * Created by etsai on 11/12/16.
 */

class _ConfigEditor extends ConfigEditor {
    Mode newMode = Mode.SLEEP;
    AccRange newAccRange = AccRange.AR_16G;
    GyroRange newGyroRange = GyroRange.GR_2000DPS;
    List<dynamic> extraAcc = null,
        extraGyro = null;

    final SensorFusionBoschImpl _impl;

    _ConfigEditor(this._impl);


    @override
    ConfigEditor mode(Mode mode) {
        newMode = mode;
        return this;
    }

    @override
    ConfigEditor accRange(AccRange range) {
        newAccRange = range;
        return this;
    }

    @override
    ConfigEditor gyroRange(GyroRange range) {
        newGyroRange = range;
        return this;
    }

    @override
    ConfigEditor accExtra(List<dynamic> settings) {
        extraAcc = settings;
        return this;
    }

    @override
    ConfigEditor gyroExtra(List<dynamic> settings) {
        extraGyro = settings;
        return this;
    }

    void addExtraAcc(AccelerometerBmi160.ConfigEditor editor) {
        if (extraAcc == null) return;
        for (Object it in extraAcc) {
            if (it is AccelerometerBmi160.FilterMode) {
                editor.filter(it as AccelerometerBmi160.FilterMode);
            }
        }
    }

    void addExtraGyro(GyroBmi160.ConfigEditor editor) {
        if (extraGyro == null) return;
        for (Object it in extraGyro) {
            if (it is GyroBmi160.FilterMode) {
                editor.filter(it as GyroBmi160.FilterMode);
            }
        }
    }

    @override
    void commit() {
        _impl.mode = newMode;

        _impl.mwPrivate.sendCommand(Uint8List.fromList([
            ModuleType.SENSOR_FUSION.id,
            SensorFusionBoschImpl.MODE,
            newMode.index,
            (newAccRange.index | ((newGyroRange.index + 1) << 4))
        ]));

        Accelerometer.Accelerometer acc = _impl.mwPrivate
            .getModules()[Accelerometer.Accelerometer] as Accelerometer
            .Accelerometer;
        GyroBmi160.GyroBmi160 gyro = _impl.mwPrivate.getModules()[GyroBmi160
            .GyroBmi160] as GyroBmi160.GyroBmi160;
        MagnetometerBmm150.MagnetometerBmm150 mag = _impl.mwPrivate
            .getModules()[MagnetometerBmm150
            .MagnetometerBmm150] as MagnetometerBmm150.MagnetometerBmm150;

        switch (newMode) {
            case Mode.SLEEP:
                break;
            case Mode.NDOF:
                {
                    Accelerometer.ConfigEditor accEditor = acc.configure()
                        .odr(100)
                        .range(
                        AccelerometerBosch.AccRange.values[newAccRange.index]
                            .range);
                    if (acc is AccelerometerBmi160.AccelerometerBmi160) {
                        addExtraAcc(accEditor);
                    }
                    accEditor.commit();

                    GyroBmi160.ConfigEditor gyroEditor = gyro.configure()
                        .odr(GyroBmi160.OutputDataRate.ODR_100_HZ)
                        .range(GyroBmi160.Range.values[newGyroRange.index]);
                    addExtraGyro(gyroEditor);
                    gyroEditor.commit();

                    mag.configure()
                        .outputDataRate(
                        MagnetometerBmm150.OutputDataRate.ODR_25_HZ)
                        .commit();
                    break;
                }
            case Mode.IMU_PLUS:
                {
                    Accelerometer.ConfigEditor accEditor = acc.configure()
                        .odr(100)
                        .range(
                        AccelerometerBosch.AccRange.values[newAccRange.index]
                            .range);
                    if (acc is AccelerometerBmi160.AccelerometerBmi160) {
                        addExtraAcc(accEditor);
                    }
                    accEditor.commit();

                    GyroBmi160.ConfigEditor gyroEditor = gyro.configure()
                        .odr(GyroBmi160.OutputDataRate.ODR_100_HZ)
                        .range(GyroBmi160.Range.values[newGyroRange.index]);
                    addExtraGyro(gyroEditor);
                    gyroEditor.commit();
                    break;
                }
            case Mode.COMPASS:
                {
                    Accelerometer.ConfigEditor accEditor = acc.configure()
                        .odr(25)
                        .range(
                        AccelerometerBosch.AccRange.values[newAccRange.index]
                            .range);
                    if (acc is AccelerometerBmi160.AccelerometerBmi160) {
                        addExtraAcc(accEditor);
                    }
                    accEditor.commit();

                    mag.configure()
                        .outputDataRate(
                        MagnetometerBmm150.OutputDataRate.ODR_25_HZ)
                        .commit();
                    break;
                }
            case Mode.M4G:
                {
                    Accelerometer.ConfigEditor accEditor = acc.configure()
                        .odr(50)
                        .range(
                        AccelerometerBosch.AccRange.values[newAccRange.index]
                            .range);
                    if (acc is AccelerometerBmi160.AccelerometerBmi160) {
                        addExtraAcc(accEditor);
                    }
                    accEditor.commit();

                    mag.configure()
                        .outputDataRate(
                        MagnetometerBmm150.OutputDataRate.ODR_25_HZ)
                        .commit();
                    break;
                }
        }
    }
}

class SensorFusionBoschImpl extends ModuleImplBase implements SensorFusionBosch {
    static String createUri(DataTypeBase dataType) {
        switch (dataType.eventConfig[1]) {
            case CORRECTED_ACC:
                return "corrected-acceleration";
            case CORRECTED_ROT:
                return "corrected-angular-velocity";
            case CORRECTED_MAG:
                return "corrected-magnetic-field";
            case QUATERNION:
                return "quaternion";
            case EULER_ANGLES:
                return "euler-angles";
            case GRAVITY_VECTOR:
                return "gravity";
            case LINEAR_ACC:
                return "linear-acceleration";
            default:
                return null;
        }
    }

    static const int CALIBRATION_STATE_REV = 1,
        CALIBRATION_DATA_REV = 2;
    static const int ENABLE = 1,
        MODE = 2,
        OUTPUT_ENABLE = 3,
        CORRECTED_ACC = 4,
        CORRECTED_ROT = 5,
        CORRECTED_MAG = 6,
        QUATERNION = 7,
        EULER_ANGLES = 8,
        GRAVITY_VECTOR = 9,
        LINEAR_ACC = 0xa,
        CALIB_STATUS = 0xb,
        ACC_CALIB_DATA = 0xc,
        GYRO_CALIB_DATA = 0xd,
        MAG_CALIB_DATA = 0xe;
    static const String QUATERNION_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.QUATERNION_PRODUCER",
        EULER_ANGLES_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.EULER_ANGLES_PRODUCER",
        GRAVITY_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.GRAVITY_PRODUCER",
        LINEAR_ACC_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.LINEAR_ACC_PRODUCER",
        CORRECTED_ACC_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.CORRECTED_ACC_PRODUCER",
        CORRECTED_ROT_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.CORRECTED_ROT_PRODUCER",
        CORRECTED_MAG_PRODUCER = "com.mbientlab.metawear.impl.SensorFusionBoschImpl.CORRECTED_MAG_PRODUCER";


    Mode mode;
    int dataEnableMask;


    final StreamController<Uint8List> _readControllerCalibration = StreamController<Uint8List>();

    AsyncDataProducer correctedAccProducer, correctedAngVelProducer,
        correctedMagProducer, quaterionProducer, eulerAnglesProducer,
        gravityProducer, linearAccProducer;

    SensorFusionBoschImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate) {
        mwPrivate.tagProducer(
            CORRECTED_ACC_PRODUCER, new CorrectedAccelerationData.Default());
        mwPrivate.tagProducer(
            CORRECTED_ROT_PRODUCER, new CorrectedAngularVelocityData.Default());
        mwPrivate.tagProducer(
            CORRECTED_MAG_PRODUCER, new CorrectedMagneticFieldData.Default());
        mwPrivate.tagProducer(
            QUATERNION_PRODUCER, new QuaternionData.Default());
        mwPrivate.tagProducer(
            EULER_ANGLES_PRODUCER, new EulerAngleData.Default());
        mwPrivate.tagProducer(
            GRAVITY_PRODUCER, new AccelerationData.Default(GRAVITY_VECTOR));
        mwPrivate.tagProducer(
            LINEAR_ACC_PRODUCER, new AccelerationData.Default(LINEAR_ACC));
    }

    @override
    void init() {
        mwPrivate.addResponseHandler(
            Tuple2(ModuleType.SENSOR_FUSION.id, Util.setRead(MODE)), (
            Uint8List response) => _readControllerCalibration.add(response));
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SENSOR_FUSION)
            .revision >= CALIBRATION_STATE_REV) {
            mwPrivate.addResponseHandler(Tuple2(
                ModuleType.SENSOR_FUSION.id, Util.setRead(CALIB_STATUS)), (
                Uint8List response) =>
                _readControllerCalibration.add(response));
        }
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SENSOR_FUSION)
            .revision >= CALIBRATION_DATA_REV) {
            mwPrivate.addResponseHandler(Tuple2(
                ModuleType.SENSOR_FUSION.id, Util.setRead(ACC_CALIB_DATA)), (
                Uint8List response) =>
                _readControllerCalibration.add(response));
            mwPrivate.addResponseHandler(Tuple2(
                ModuleType.SENSOR_FUSION.id, Util.setRead(GYRO_CALIB_DATA)), (
                Uint8List response) =>
                _readControllerCalibration.add(response));
            mwPrivate.addResponseHandler(Tuple2(
                ModuleType.SENSOR_FUSION.id, Util.setRead(MAG_CALIB_DATA)), (
                Uint8List response) =>
                _readControllerCalibration.add(response));
        }
    }

    @override
    ConfigEditor configure() {
        return _ConfigEditor(this);
    }

    @override
    AsyncDataProducer correctedAcceleration() {
        if (correctedAccProducer == null) {
            correctedAccProducer = _SensorFusionAsyncDataProducer(
                this, CORRECTED_ACC_PRODUCER, 0x01);
        }
        return correctedAccProducer;
    }

    @override
    AsyncDataProducer correctedAngularVelocity() {
        if (correctedAngVelProducer == null) {
            correctedAngVelProducer = _SensorFusionAsyncDataProducer(
                this, CORRECTED_ROT_PRODUCER, 0x02);
        }
        return correctedAngVelProducer;
    }

    @override
    AsyncDataProducer correctedMagneticField() {
        if (correctedMagProducer == null) {
            correctedMagProducer = _SensorFusionAsyncDataProducer(
                this, CORRECTED_MAG_PRODUCER, 0x04);
        }
        return correctedMagProducer;
    }

    @override
    AsyncDataProducer quaternion() {
        if (quaterionProducer == null) {
            quaterionProducer =
                _SensorFusionAsyncDataProducer(this, QUATERNION_PRODUCER, 0x08);
        }
        return quaterionProducer;
    }

    @override
    AsyncDataProducer eulerAngles() {
        if (eulerAnglesProducer == null) {
            eulerAnglesProducer = _SensorFusionAsyncDataProducer(
                this, EULER_ANGLES_PRODUCER, 0x10);
        }
        return eulerAnglesProducer;
    }

    @override
    AsyncDataProducer gravity() {
        if (gravityProducer == null) {
            gravityProducer =
                _SensorFusionAsyncDataProducer(this, GRAVITY_PRODUCER, 0x20);
        }
        return gravityProducer;
    }

    @override
    AsyncDataProducer linearAcceleration() {
        if (linearAccProducer == null) {
            linearAccProducer =
                _SensorFusionAsyncDataProducer(this, LINEAR_ACC_PRODUCER, 0x40);
        }
        return linearAccProducer;
    }

    @override
    void start() {
        Accelerometer.Accelerometer acc = mwPrivate.getModules()[Accelerometer
            .Accelerometer ] as Accelerometer.Accelerometer;
        GyroBmi160.GyroBmi160 gyro = mwPrivate.getModules()[GyroBmi160
            .GyroBmi160] as GyroBmi160.GyroBmi160;
        MagnetometerBmm150.MagnetometerBmm150 mag = mwPrivate
            .getModules()[MagnetometerBmm150
            .MagnetometerBmm150] as MagnetometerBmm150.MagnetometerBmm150;

        switch (mode) {
            case Mode.SLEEP:
                break;
            case Mode.NDOF:
                acc.acceleration().start();
                gyro.angularVelocity().start();
                mag.magneticField().start();
                acc.start();
                gyro.start();
                mag.start();
                break;
            case Mode.IMU_PLUS:
                acc.acceleration().start();
                gyro.angularVelocity().start();
                acc.start();
                gyro.start();
                break;
            case Mode.COMPASS:
            case Mode.M4G:
                acc.acceleration().start();
                mag.magneticField().start();
                acc.start();
                mag.start();
                break;
        }

        mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.SENSOR_FUSION.id, OUTPUT_ENABLE, dataEnableMask, 0x00
            ]));
        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.SENSOR_FUSION.id, ENABLE, 0x1]));
    }

    @override
    void stop() {
        Accelerometer.Accelerometer acc = mwPrivate.getModules()[Accelerometer
            .Accelerometer ] as Accelerometer.Accelerometer;
        GyroBmi160.GyroBmi160 gyro = mwPrivate.getModules()[GyroBmi160
            .GyroBmi160] as GyroBmi160.GyroBmi160;
        MagnetometerBmm150.MagnetometerBmm150 mag = mwPrivate
            .getModules()[MagnetometerBmm150
            .MagnetometerBmm150] as MagnetometerBmm150.MagnetometerBmm150;

        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.SENSOR_FUSION.id, ENABLE, 0x0]));
        mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.SENSOR_FUSION.id, OUTPUT_ENABLE, 0x00, 0x7f]));

        switch (mode) {
            case Mode.SLEEP:
                break;
            case Mode.NDOF:
                acc.stop();
                gyro.stop();
                mag.stop();
                acc.acceleration().stop();
                gyro.angularVelocity().stop();
                mag.magneticField().stop();
                break;
            case Mode.IMU_PLUS:
                acc.stop();
                gyro.stop();
                acc.acceleration().stop();
                gyro.angularVelocity().stop();
                break;
            case Mode.COMPASS:
            case Mode.M4G:
                acc.stop();
                mag.stop();
                acc.acceleration().stop();
                mag.magneticField().stop();
                break;
        }
    }

    @override
    Future<void> pullConfigAsync() async {
        Stream<Uint8List> stream = _readControllerCalibration.stream.timeout(
            ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);

        mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.SENSOR_FUSION.id, Util.setRead(MODE)]));
        TimeoutException exception = TimeoutException(
            "Did not receive sensor fusion config ",
            ModuleType.RESPONSE_TIMEOUT);
        if (await iterator.moveNext().catchError((e) => throw exception,
            test: (e) => e is TimeoutException) == false)
            throw exception;
        Uint8List result = iterator.current;

        mode = Mode.values[result[2]];
        await iterator.cancel();
    }


    @override
    Future<CalibrationState> readCalibrationStateAsync() async {
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SENSOR_FUSION)
            .revision >= CALIBRATION_STATE_REV) {
            Stream<Uint8List> stream = _readControllerCalibration.stream
                .timeout(ModuleType.RESPONSE_TIMEOUT);
            StreamIterator<Uint8List> iterator = StreamIterator(stream);

            mwPrivate.sendCommand(Uint8List.fromList(
                [ModuleType.SENSOR_FUSION.id, Util.setRead(CALIB_STATUS)]));
            TimeoutException exception = TimeoutException(
                "Did not receive sensor fusion calibration",
                ModuleType.RESPONSE_TIMEOUT);
            if (await iterator.moveNext().catchError((e) => throw exception,
                test: (e) => e is TimeoutException) == false)
                throw exception;
            Uint8List result = iterator.current;
            await iterator.cancel();
            return CalibrationState(
                CalibrationAccuracy.values[result[2]],
                CalibrationAccuracy.values[result[3]],
                CalibrationAccuracy.values[result[4]]
            );
        }
        return throw UnsupportedError(
            "Minimum firmware v1.4.2 required to use this function");
    }


    Future<CalibrationData> calibrate({void updateHandler(
        CalibrationState state), int pollingPeriod = 1000}) async {
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SENSOR_FUSION)
            .revision >= CALIBRATION_DATA_REV) {
            bool terminate;
            Uint8List acc;
            Uint8List gyro;
            Uint8List mag;


            while (true) {
                CalibrationState state = await readCalibrationStateAsync();
                if (updateHandler != null) {
                    updateHandler(state);
                }
                switch (mode) {
                    case Mode.NDOF:
                        if (state.accelerometer ==
                            CalibrationAccuracy.HIGH_ACCURACY &&
                            state.gyroscope ==
                                CalibrationAccuracy.HIGH_ACCURACY &&
                            state.magnetometer ==
                                CalibrationAccuracy.HIGH_ACCURACY)
                            terminate = true;

                        break;

                    case Mode.IMU_PLUS:
                        if (state.accelerometer ==
                            CalibrationAccuracy.HIGH_ACCURACY &&
                            state.gyroscope ==
                                CalibrationAccuracy.HIGH_ACCURACY)
                            terminate = true;

                        break;

                    case Mode.COMPASS:
                        if (state.accelerometer ==
                            CalibrationAccuracy.HIGH_ACCURACY &&
                            state.magnetometer ==
                                CalibrationAccuracy.HIGH_ACCURACY)
                            terminate = true;

                        break;
                    case Mode.M4G:
                        if (state.accelerometer ==
                            CalibrationAccuracy.HIGH_ACCURACY &&
                            state.magnetometer ==
                                CalibrationAccuracy.HIGH_ACCURACY)
                            terminate = true;

                        break;
                    default:
                        break;
                }
                if (terminate == true)
                    break;
                await Future.delayed(Duration(milliseconds: pollingPeriod));
            }

            Stream<Uint8List> stream = _readControllerCalibration.stream
                .timeout(ModuleType.RESPONSE_TIMEOUT);
            StreamIterator<Uint8List> iterator = StreamIterator(stream);

            // try get accelerometer calibration
            TimeoutException exception = TimeoutException(
                "Did not receive accelerometer calibration",
                ModuleType.RESPONSE_TIMEOUT);
            mwPrivate.sendCommand(Uint8List.fromList(
                [ModuleType.SENSOR_FUSION.id, Util.setRead(ACC_CALIB_DATA)]));
            if (await iterator.moveNext().catchError((e) => throw exception,
                test: (e) => e is TimeoutException) == false)
                throw exception;
            Uint8List result = iterator.current;
            acc.setAll(0, result.skip(2));

            // try get gyro calibration
            if (mode == Mode.IMU_PLUS || mode == Mode.NDOF) {
                exception = TimeoutException(
                    "Did not receive gyroscope calibration data",
                    ModuleType.RESPONSE_TIMEOUT);
                mwPrivate.sendCommand(Uint8List.fromList(
                    [ModuleType.SENSOR_FUSION.id, Util.setRead(GYRO_CALIB_DATA)
                    ]));
                if (await iterator.moveNext().catchError((e) => throw exception,
                    test: (e) => e is TimeoutException) == false)
                    throw exception;
                Uint8List result = iterator.current;
                gyro.setAll(0, result.skip(2));
            }

            // try get mag calibration
            if (mode != Mode.IMU_PLUS) {
                exception = TimeoutException(
                    "Did not receive magnetometer calibration",
                    ModuleType.RESPONSE_TIMEOUT);
                mwPrivate.sendCommand(Uint8List.fromList(
                    [ModuleType.SENSOR_FUSION.id, Util.setRead(MAG_CALIB_DATA)
                    ]));
                if (await iterator.moveNext().catchError((e) => throw exception,
                    test: (e) => e is TimeoutException) == false)
                    throw exception;
                Uint8List result = iterator.current;
                mag.setAll(0, result.skip(2));
            }

            await iterator.cancel();


            return CalibrationData(acc, gyro, mag);
        }
        return throw UnsupportedError(
            "Minimum firmware v1.4.4 required to use this function");
    }

    @override
    void writeCalibrationData(CalibrationData data) {
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SENSOR_FUSION)
            .revision >= CALIBRATION_STATE_REV) {
            mwPrivate.sendCommandForModule(
                ModuleType.SENSOR_FUSION, SensorFusionBoschImpl.ACC_CALIB_DATA,
                data.accelerometer);

            if (mode == Mode.IMU_PLUS || mode == Mode.NDOF) {
                mwPrivate.sendCommandForModule(ModuleType.SENSOR_FUSION,
                    SensorFusionBoschImpl.GYRO_CALIB_DATA, data.gyroscope);
            }

            if (mode != Mode.IMU_PLUS) {
                mwPrivate.sendCommandForModule(ModuleType.SENSOR_FUSION,
                    SensorFusionBoschImpl.MAG_CALIB_DATA, data.magnetometer);
            }
        }
    }
}
