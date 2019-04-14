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
import 'package:flutter_metawear/impl/FloatVectorData.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/module/AccelerometerBosch.dart' as AccelerometerBosch;
import 'dart:typed_data';
import 'package:sprintf/sprintf.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';

abstract class BoschFlatDataProducer implements AccelerometerBosch.FlatDataProducer {
    final MetaWearBoardPrivate _mwPrivate;

    BoschFlatDataProducer(this._mwPrivate);

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return _mwPrivate.queueRouteBuilder(builder, AccelerometerBoschImpl.FLAT_PRODUCER);
    }

    @override
    String name() {
        return AccelerometerBoschImpl.FLAT_PRODUCER;
    }

    @override
    void start() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, AccelerometerBoschImpl.FLAT_INTERRUPT_ENABLE, 1, 0]));
    }

    @override
    void stop() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, AccelerometerBoschImpl.FLAT_INTERRUPT_ENABLE, 0, 1]));
    }
}

class LowHighConfigEditor extends AccelerometerBosch.LowHighConfigEditor {
    AccelerometerBosch.LowGMode _lowGMode;
    int _lowDuration = null,
        _highDuration = null;
    double _lowThreshold = null,
        _lowHysteresis = null,
        _newHighThreshold = null,
        _newHighHysteresis = null;
    int _lowHighEnableMask = 0;

    final AccelerometerBoschImpl _impl;
    final Uint8List _lowHighConfig;
    final LowHighDataProducerInner _highDataProducerInner;

    LowHighConfigEditor(this._lowHighConfig,this._highDataProducerInner,this._impl);


    @override
    void commit() {
        if (_lowDuration != null) {
            _lowHighConfig[0] = ((_lowDuration.toDouble() / _highDataProducerInner.durationStep) - 1).toInt();
        }
        if (_lowThreshold != null) {
            _lowHighConfig[1] = (_lowThreshold.toDouble() / AccelerometerBoschImpl.LOW_THRESHOLD_STEP.toDouble()).toInt();
        }
        if (_newHighHysteresis != null) {
            _lowHighConfig[2] |= ((_newHighHysteresis / AccelerometerBoschImpl.BOSCH_HIGH_HYSTERESIS_STEPS[_impl.getSelectedAccRange()]).toInt() & 0x3) << 6;
        }
        if (lowGMode != null) {
            _lowHighConfig[2] &= 0xfb;
            _lowHighConfig[2] |= (_lowGMode.index << 2);
        }
        if (_lowHysteresis  != null) {
            _lowHighConfig[2] &= 0xfc;
            _lowHighConfig[2] |= ((_lowHysteresis / AccelerometerBoschImpl.LOW_HYSTERESIS_STEP).toInt() & 0x3);
        }
        if (_highDuration != null) {
            _lowHighConfig[3] = ((_highDuration / _highDataProducerInner.durationStep) - 1).toInt();
        }
        if (_newHighThreshold != null) {
            _lowHighConfig[4] = (_newHighThreshold / AccelerometerBoschImpl.BOSCH_HIGH_THRESHOLD_STEPS[_impl.getSelectedAccRange()]).toInt();
        }

        _impl.mwPrivate.sendCommandForModule(ModuleType.ACCELEROMETER, AccelerometerBoschImpl.LOW_HIGH_G_CONFIG, _lowHighConfig);
    }

    @override
    AccelerometerBosch.LowHighConfigEditor enableHighGx() {
        _lowHighEnableMask |= 0x1;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor enableHighGy() {
        _lowHighEnableMask |= 0x2;
        return null;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor enableHighGz() {
        _lowHighEnableMask |= 0x4;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor enableLowG() {
        _lowHighEnableMask |= 0x8;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor highDuration(int duration) {
        _highDuration = duration;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor highHysteresis(double hysteresis) {
        _newHighHysteresis = hysteresis;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor highThreshold(double threshold) {
        _newHighThreshold = threshold;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor lowDuration(int duration) {
        _lowDuration = duration;
        return null;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor lowGMode(
        AccelerometerBosch.LowGMode mode) {
        _lowGMode = mode;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor lowHysteresis(double hysteresis) {
        _lowHysteresis = hysteresis;
        return this;
    }

    @override
    AccelerometerBosch.LowHighConfigEditor lowThreshold(double threshold) {
        _lowThreshold = threshold;
        return this;
    }
}

class LowHighDataProducerInner implements AccelerometerBosch.LowHighDataProducer {
    final Uint8List initialConfig;
    final double durationStep;
    final MetaWearBoardPrivate _mwPrivate;
    int lowHighEnableMask = 0;

    LowHighDataProducerInner(this._mwPrivate,this.initialConfig,this.durationStep);


    @override
    AccelerometerBosch.LowHighConfigEditor configure() {
        final Uint8List lowHighConfig = []..addAll(initialConfig);
        lowHighEnableMask = 0;
        return null;
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return _mwPrivate.queueRouteBuilder(builder, AccelerometerBoschImpl.LOW_HIGH_PRODUCER);
    }

    @override
    String name() {
        return AccelerometerBoschImpl.LOW_HIGH_PRODUCER;
    }

    @override
    void start() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, AccelerometerBoschImpl.LOW_HIGH_G_INTERRUPT_ENABLE, lowHighEnableMask, 0x0]));
    }

    @override
    void stop() {
        _mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, AccelerometerBoschImpl.LOW_HIGH_G_INTERRUPT_ENABLE, 0, 0xf]));
    }

}
class AnyMotionConfigEditorInner implements AccelerometerBosch.AnyMotionConfigEditor {
    int _count= null;
    double _threshold= null;
    final Uint8List _motionConfig;

    AnyMotionConfigEditorInner(this._motionConfig);

    @override
    AccelerometerBosch.AnyMotionConfigEditor count(int count) {
        this._count = count;
        return this;;
    }

    @override
    AccelerometerBosch.AnyMotionConfigEditor threshold(double threshold) {
        this._threshold = threshold;
        return this;
    }

    @override
    void commit() {
        if (count != null) {
            _motionConfig[0]&= 0xfc;
            _motionConfig[0]|= (_count - 1) & 0x3;
        }

        if (_threshold != null) {
            _motionConfig[1]= (threshold / BOSCH_ANY_MOTION_THS_STEPS[getSelectedAccRange()]);
        }

        mwPrivate.sendCommand(ACCELEROMETER, MOTION_CONFIG, motionConfig);
    }


}
class SlowMotionConfigEditorInner implements SlowMotionConfigEditor {
    int count= null;
    double threshold= null;
    final Uint8List motionConfig;

    SlowMotionConfigEditorInner(byte[] initialConfig) {
    motionConfig = initialConfig;
    }

    @override
    SlowMotionConfigEditor count(byte count) {
        this.count= count;
        return this;
    }

    @override
    SlowMotionConfigEditor threshold(float threshold) {
        this.threshold= threshold;
        return this;
    }

    @override
    void commit() {
        if (count != null) {
            motionConfig[0]&= 0x3;
            motionConfig[0]|= (count - 1) << 2;
        }
        if (threshold != null) {
            motionConfig[2]= (byte) (threshold / BOSCH_NO_MOTION_THS_STEPS[getSelectedAccRange()]);
        }

        mwPrivate.sendCommand(ACCELEROMETER, MOTION_CONFIG, motionConfig);
    }
}

class BoschAccCartesianFloatData extends FloatVectorData {
    BoschAccCartesianFloatData.Default() : super(DATA_INTERRUPT,  1);

    BoschAccCartesianFloatData.Register(int register, int copies) {
        super(ACCELEROMETER, register, new DataAttributes(new byte[] {2, 2, 2}, copies, (byte) 0, true));
    }

    BoschAccCartesianFloatData(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschAccCartesianFloatData(input, module, register, id, attributes);
    }

    @override
    DataTypeBase[] createSplits() {
        return new DataTypeBase[] {new BoschAccSFloatData((byte) 0), new BoschAccSFloatData((byte) 2), new BoschAccSFloatData((byte) 4)};
        }

    @override
    protected float scale(MetaWearBoardPrivate mwPrivate) {
        return ((AccelerometerBoschImpl) mwPrivate.getModules().get(AccelerometerBosch.class)).getAccDataScale();
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, final byte[] data, final Calendar timestamp, DataPrivate.ClassToObject mapper) {
    ByteBuffer buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN);
    short[] unscaled = new short[]{buffer.getShort(), buffer.getShort(), buffer.getShort()};
    final float scale= scale(mwPrivate);
    final Acceleration value= new Acceleration(unscaled[0] / scale, unscaled[1] / scale, unscaled[2] / scale);

    return new DataPrivate(timestamp, data, mapper) {
    @override
    float scale() {
    return scale;
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {Acceleration.class, float[].class};
    }

    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(Acceleration.class)) {
    return clazz.cast(value);
    } else if (clazz.equals(float[].class)) {
    return clazz.cast(new float[] {value.x(), value.y(), value.z()});
    }
    return super.value(clazz);
    }
    };
    }
}
class BoschAccSFloatData extends SFloatData {

    BoschAccSFloatData.offset(int offset): super(ModuleType.ACCELEROMETER, DATA_INTERRUPT, new DataAttributes(new byte[] {2}, (byte) 1, offset, true));


    BoschAccSFloatData(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    @override
    double scale(MetaWearBoardPrivate mwPrivate) {
        return ((AccelerometerBoschImpl) mwPrivate.getModules().get(AccelerometerBosch.class)).getAccDataScale();
    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschAccSFloatData(input, module, register, id, attributes);
    }
}
class BoschFlatData extends DataTypeBase {

    BoschFlatData(): super(ModuleType.ACCELEROMETER, FLAT_INTERRUPT, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));


    BoschFlatData(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschFlatData(input, module, register, id, attributes);
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, byte[] data, Calendar timestamp, DataPrivate.ClassToObject mapper) {
    int mask = mwPrivate.lookupModuleInfo(ACCELEROMETER).revision >= FLAT_REVISION ? 0x4 : 0x2;
    final boolean isFlat = (data[0] & mask) == mask;

    return new DataPrivate(timestamp, data, mapper) {
    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(Boolean.class)) {
    return clazz.cast(isFlat);
    }
    return super.value(clazz);
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {Boolean.class};
    }
    };
    }
}
class BoschOrientationData extends DataTypeBase {

    BoschOrientationData.Default(): super(ModuleType.ACCELEROMETER, ORIENT_INTERRUPT, new DataAttributes(Uint8List.fromList([1]), 1, 0, false));


    BoschOrientationData(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes): super(module, register, attributes,input:input,id:id);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschOrientationData(input, module, register, id, attributes);
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, byte[] data, Calendar timestamp, DataPrivate.ClassToObject mapper) {
    final SensorOrientation orientation = SensorOrientation.values()[((data[0] & 0x6) >> 1) + 4 * ((data[0] & 0x8) >> 3)];

    return new DataPrivate(timestamp, data, mapper) {
    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(SensorOrientation.class)) {
    return clazz.cast(orientation);
    }
    return super.value(clazz);
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {SensorOrientation.class};
    }
    };
    }
}
class BoschLowHighData extends DataTypeBase {

    BoschLowHighData() {
        super(ACCELEROMETER, LOW_HIGH_G_INTERRUPT, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));
    }

    BoschLowHighData(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschLowHighData(input, module, register, id, attributes);
    }

    private boolean highG(CartesianAxis axis, byte value) {
        byte mask= (byte) (0x1 << axis.ordinal());
        return (value & mask) == mask;
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, final byte[] data, Calendar timestamp, DataPrivate.ClassToObject mapper) {
    final byte highFirst = (byte) ((data[0] & 0x1c) >> 2);
    final LowHighResponse castedData = new LowHighResponse(
    (data[0] & 0x1) == 0x1,
    (data[0] & 0x2) == 0x2,
    highG(CartesianAxis.X, highFirst),
    highG(CartesianAxis.Y, highFirst),
    highG(CartesianAxis.Z, highFirst),
    (data[0] & 0x20) == 0x20 ? Sign.NEGATIVE : Sign.POSITIVE);

    return new DataPrivate(timestamp, data, mapper) {
    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(LowHighResponse.class)) {
    return clazz.cast(castedData);
    }
    return super.value(clazz);
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {LowHighResponse.class};
    }
    };
    }
}
class BoschMotionData extends DataTypeBase {

    BoschMotionData.Default(): super(ModuleType.ACCELEROMETER, MOTION_INTERRUPT, new DataAttributes(Uint8List.fromList([1]), 1, 0, false));


    BoschMotionData(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) : super(input, module, register, id, attributes);


    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        return new BoschMotionData(input, module, register, id, attributes);
    }

    bool detected(CartesianAxis axis, int value) {
        int mask= (0x1 << (axis.ordinal() + 3));
        return (value & mask) == mask;
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, final Uint8List data, DateTime timestamp, DataPrivate.ClassToObject mapper) {
    final AnyMotion castedData = new AnyMotion(
    (data[0] & 0x40) == 0x40 ? Sign.NEGATIVE : Sign.POSITIVE,
    detected(CartesianAxis.X, data[0]),
    detected(CartesianAxis.Y, data[0]),
    detected(CartesianAxis.Z, data[0])
    );

    return new DataPrivate(timestamp, data, mapper) {
    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(AnyMotion.class)) {
    return clazz.cast(castedData);
    }
    return super.value(clazz);
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {AnyMotion.class};
    }
    };
    }
}
class BoschTapData extends DataTypeBase {
    
    BoschTapData.Default():super(ModuleType.ACCELEROMETER, TAP_INTERRUPT, new DataAttributes(Uint8List.fromList([1]), 1, 0, false));
    

    BoschTapData(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes): super(input, module, register, id, attributes);
    

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, byte register, byte id, DataAttributes attributes) {
        return new BoschTapData(input, module, register, id, attributes);
    }

    @override
    Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, final byte[] data, Calendar timestamp, DataPrivate.ClassToObject mapper) {
    TapType type = null;
    if ((data[0] & 0x1) == 0x1) {
    type = TapType.DOUBLE;
    } else if ((data[0] & 0x2) == 0x2) {
    type = TapType.SINGLE;
    }

    final Tap castedData = new Tap(type, (data[0] & 0x20) == 0x20 ? Sign.NEGATIVE : Sign.POSITIVE);
    return new DataPrivate(timestamp, data, mapper) {
    @override
    <T> T value(Class<T> clazz) {
    if (clazz.equals(Tap.class)) {
    return clazz.cast(castedData);
    }
    return super.value(clazz);
    }

    @override
    Class<?>[] types() {
    return new Class<?>[] {Tap.class};
    }
    };
    }
}

/**
 * Created by etsai on 9/1/16.
 */
abstract class AccelerometerBoschImpl extends ModuleImplBase implements AccelerometerBosch {
    static String createUri(DataTypeBase dataType) {
        switch (dataType.eventConfig[1]) {
            case DATA_INTERRUPT:
                return dataType.attributes.length() > 2 ? "acceleration" : sprintf("acceleration[%d]", (dataType.attributes.offset >> 1));
            case ORIENT_INTERRUPT:
                return "orientation";
            case FLAT_INTERRUPT:
                return "bosch-flat";
            case LOW_HIGH_G_INTERRUPT:
                return "bosch-low-high";
            case MOTION_INTERRUPT:
                return "bosch-motion";
            case TAP_INTERRUPT:
                return "bosch-tap";
            case PACKED_ACC_DATA:
                return "acceleration";
            default:
                return null;
        }
    }

    static const int PACKED_ACC_REVISION = 0x1, FLAT_REVISION = 0x2;
    static const double LOW_THRESHOLD_STEP = 0.00781, LOW_HYSTERESIS_STEP= 0.125;
    static const List<double> BOSCH_HIGH_THRESHOLD_STEPS= [0.00781, 0.01563, 0.03125, 0.0625],
            BOSCH_HIGH_HYSTERESIS_STEPS= [0.125, 0.250, 0.5, 1.0],
            BOSCH_ANY_MOTION_THS_STEPS= [0.00391, 0.00781, 0.01563, 0.03125];
    static const List<double> BOSCH_NO_MOTION_THS_STEPS= BOSCH_ANY_MOTION_THS_STEPS;
    static const List<double> BOSCH_TAP_THS_STEPS= [0.0625, 0.125, 0.250, 0.5];
    static const int POWER_MODE = 1,
            DATA_INTERRUPT_ENABLE = 2, DATA_CONFIG = 3, DATA_INTERRUPT = 4, DATA_INTERRUPT_CONFIG = 5,
            ORIENT_INTERRUPT_ENABLE = 0xf, ORIENT_CONFIG = 0x10, ORIENT_INTERRUPT = 0x11,
            LOW_HIGH_G_INTERRUPT_ENABLE = 0x6, LOW_HIGH_G_CONFIG = 0x7, LOW_HIGH_G_INTERRUPT = 0x8,
            MOTION_INTERRUPT_ENABLE = 0x9, MOTION_CONFIG = 0xa, MOTION_INTERRUPT = 0xb,
            TAP_INTERRUPT_ENABLE = 0xc, TAP_CONFIG = 0xd, TAP_INTERRUPT = 0xe,
            FLAT_INTERRUPT_ENABLE = 0x12, FLAT_CONFIG = 0x13, FLAT_INTERRUPT = 0x14,
            PACKED_ACC_DATA= 0x1c;
    static const String ACCEL_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ACCEL_PRODUCER",
            ACCEL_X_AXIS_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ACCEL_X_AXIS_PRODUCER",
            ACCEL_Y_AXIS_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ACCEL_Y_AXIS_PRODUCER",
            ACCEL_Z_AXIS_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ACCEL_Z_AXIS_PRODUCER",
            ACCEL_PACKED_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ACCEL_PACKED_PRODUCER",
            LOW_HIGH_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.LOW_HIGH_PRODUCER",
            ORIENTATION_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.ORIENTATION_PRODUCER",
            FLAT_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.FLAT_PRODUCER",
            MOTION_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.MOTION_PRODUCER",
            TAP_PRODUCER= "com.mbientlab.metawear.impl.AccelerometerBoschImpl.TAP_PRODUCER";
    static const double ORIENT_HYS_G_PER_STEP= 0.0625, THETA_STEP= (44.8/63.0);




    int tapEnableMask;
    AsyncDataProducer packedAcceleration, acceleration, orientation, tap;

    AccelerometerBoschImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate){

        DataTypeBase cfProducer = new BoschAccCartesianFloatData.Default();

        this.mwPrivate= mwPrivate;
        this.mwPrivate.tagProducer(ACCEL_PRODUCER, cfProducer);
        this.mwPrivate.tagProducer(ACCEL_X_AXIS_PRODUCER, cfProducer.split[0]);
        this.mwPrivate.tagProducer(ACCEL_Y_AXIS_PRODUCER, cfProducer.split[1]);
        this.mwPrivate.tagProducer(ACCEL_Z_AXIS_PRODUCER, cfProducer.split[2]);
        this.mwPrivate.tagProducer(FLAT_PRODUCER, new BoschFlatData());
        this.mwPrivate.tagProducer(ORIENTATION_PRODUCER, new BoschOrientationData());
        this.mwPrivate.tagProducer(LOW_HIGH_PRODUCER, new BoschLowHighData());
        this.mwPrivate.tagProducer(MOTION_PRODUCER, new BoschMotionData());
        this.mwPrivate.tagProducer(TAP_PRODUCER, new BoschTapData());
        this.mwPrivate.tagProducer(ACCEL_PACKED_PRODUCER, new BoschAccCartesianFloatData(PACKED_ACC_DATA, (byte) 3));
    }

    double getAccDataScale();
    int getSelectedAccRange();
    int getMaxOrientHys();
    void writeFlatConfig(int holdTime, double theta) {
        Uint8List flatConfig = Uint8List.fromList([0x08, 0x11]);

        flatConfig[0]|= ((theta / THETA_STEP) & 0x3f);
        flatConfig[1]|= (holdTime << 4);

        mwPrivate.sendCommandForModule(ModuleType.ACCELEROMETER, FLAT_CONFIG, flatConfig);
    }

    @override
    AccelerationDataProducer acceleration() {
        if (acceleration == null) {
            acceleration = new AccelerationDataProducer() {
                @override
                Future<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, ACCEL_PRODUCER);
                }

                @override
                String name() {
                    return ACCEL_PRODUCER;
                }

                @override
                void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, DATA_INTERRUPT_ENABLE, 0x01, 0x00});
                }

                @override
                void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, DATA_INTERRUPT_ENABLE, 0x00, 0x01});
                }

                @override
                String xAxisName() {
                    return ACCEL_X_AXIS_PRODUCER;
                }

                @override
                String yAxisName() {
                    return ACCEL_Y_AXIS_PRODUCER;
                }

                @override
                String zAxisName() {
                    return ACCEL_Z_AXIS_PRODUCER;
                }
            };
        }
        return (AccelerationDataProducer) acceleration;
    }

    @override
    AsyncDataProducer packedAcceleration() {
        if (mwPrivate.lookupModuleInfo(ACCELEROMETER).revision >= PACKED_ACC_REVISION) {
            if (packedAcceleration == null) {
                packedAcceleration = new AsyncDataProducer() {
                    @override
                    Future<Route> addRouteAsync(RouteBuilder builder) {
                        return mwPrivate.queueRouteBuilder(builder, ACCEL_PACKED_PRODUCER);
                    }

                    @override
                    String name() {
                        return ACCEL_PACKED_PRODUCER;
                    }

                    @override
                    void start() {
                        mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, DATA_INTERRUPT_ENABLE, 0x01, 0x00});
                    }

                    @override
                    void stop() {
                        mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, DATA_INTERRUPT_ENABLE, 0x00, 0x01});
                    }
                };
            }
            return packedAcceleration;
        }
        return null;
    }

    @override
    void start() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, POWER_MODE, 0x01]));
    }

    @override
    void stop() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.ACCELEROMETER.id, POWER_MODE, 0x00]));
    }

    @override
    OrientationDataProducer orientation() {
        if (orientation == null) {
            orientation = new OrientationDataProducer() {
                @override
                OrientationConfigEditor configure() {
                    return new OrientationConfigEditor() {
                        private Float hysteresis = null;
                        private OrientationMode mode = OrientationMode.SYMMETRICAL;

                        @override
                        OrientationConfigEditor hysteresis(float hysteresis) {
                            this.hysteresis = hysteresis;
                            return this;
                        }

                        @override
                        OrientationConfigEditor mode(OrientationMode mode) {
                            this.mode = mode;
                            return this;
                        }

                        @override
                        void commit() {
                            byte[] orientationConfig = new byte[] {0x18, 0x48};

                            if (hysteresis != null) {
                                orientationConfig[0]|= (byte) Math.min(getMaxOrientHys(), (byte) (hysteresis / ORIENT_HYS_G_PER_STEP));
                            }

                            orientationConfig[0]&= 0xfc;
                            orientationConfig[0]|= mode.ordinal();

                            mwPrivate.sendCommand(ACCELEROMETER, ORIENT_CONFIG, orientationConfig);
                        }
                    };
                }

                @override
                Future<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, ORIENTATION_PRODUCER);
                }

                @override
                String name() {
                    return ORIENTATION_PRODUCER;
                }

                @override
                void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, ORIENT_INTERRUPT_ENABLE, (byte) 0x1, (byte) 0x0});
                }

                @override
                void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, ORIENT_INTERRUPT_ENABLE, (byte) 0x0, (byte) 0x1});
                }
            };
        }
        return (OrientationDataProducer) orientation;
    }

    @override
    TapDataProducer tap() {
        if (tap == null) {
            tap = new TapDataProducer() {
                @override
                Future<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, TAP_PRODUCER);
                }

                @override
                String name() {
                    return TAP_PRODUCER;
                }

                @override
                void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, TAP_INTERRUPT_ENABLE, tapEnableMask, (byte) 0});
                }

                @override
                void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, TAP_INTERRUPT_ENABLE, (byte) 0, (byte) 0x3});
                }

                @override
                TapConfigEditor configure() {
                    return new TapConfigEditor() {
                        private TapQuietTime newTapTime= null;
                        private TapShockTime newShockTime= null;
                        private DoubleTapWindow newWindow= null;
                        private Float newThs= null;
                        private final LinkedHashSet<TapType> types = new LinkedHashSet<>();

                        @override
                        TapConfigEditor enableDoubleTap() {
                            types.add(TapType.DOUBLE);
                            return this;
                        }

                        @override
                        TapConfigEditor enableSingleTap() {
                            types.add(TapType.SINGLE);
                            return this;
                        }

                        @override
                        TapConfigEditor quietTime(TapQuietTime time) {
                            newTapTime= time;
                            return this;
                        }

                        @override
                        TapConfigEditor shockTime(TapShockTime time) {
                            newShockTime= time;
                            return this;
                        }

                        @override
                        TapConfigEditor doubleTapWindow(DoubleTapWindow window) {
                            newWindow= window;
                            return this;
                        }

                        @override
                        TapConfigEditor threshold(float threshold) {
                            newThs= threshold;
                            return this;
                        }

                        @override
                        void commit() {
                            byte[] tapConfig = new byte[] {0x04, 0x0a};

                            if (newTapTime != null) {
                                tapConfig[0]|= newTapTime.ordinal() << 7;
                            }

                            if (newShockTime != null) {
                                tapConfig[0]|= newShockTime.ordinal() << 6;
                            }

                            if (newWindow != null) {
                                tapConfig[0]&= 0xf8;
                                tapConfig[0]|= newWindow.ordinal();
                            }

                            if (newThs != null) {
                                tapConfig[1]&= 0xe0;
                                tapConfig[1]|= (byte) Math.min(15, newThs / BOSCH_TAP_THS_STEPS[getSelectedAccRange()]);
                            }

                            tapEnableMask= 0;
                            if (types.isEmpty()) {
                                types.add(TapType.SINGLE);
                                types.add(TapType.DOUBLE);
                            }
                            for(TapType it: types) {
                                switch (it) {
                                    case SINGLE:
                                        tapEnableMask |= 0x2;
                                        break;
                                    case DOUBLE:
                                        tapEnableMask |= 0x1;
                                        break;
                                }
                            }

                            mwPrivate.sendCommand(ACCELEROMETER, TAP_CONFIG, tapConfig);
                        }
                    };
                }
            };
        }
        return (TapDataProducer) tap;
    }
}
