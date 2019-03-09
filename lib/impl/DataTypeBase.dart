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

import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:tuple/tuple.dart';

/**
 * Created by etsai on 9/4/16.
 */
abstract class DataTypeBase implements DataToken {
    static String createUri(DataTypeBase dataType, MetaWearBoardPrivate mwPrivate) {
        String uri = null;
        switch (ModuleType.lookupEnum(dataType.eventConfig[0])) {
            case ModuleType.SWITCH:
                uri = SwitchImpl.createUri(dataType);
                break;
            case ModuleType.ACCELEROMETER:
                Object module = mwPrivate.getModules().get(Accelerometer.class);
                if (module instanceof AccelerometerMma8452q) {
                    uri = AccelerometerMma8452qImpl.createUri(dataType);
                } else if (module instanceof AccelerometerBmi160) {
                    uri = AccelerometerBmi160Impl.createUri(dataType);
                } else if (module instanceof AccelerometerBma255) {
                    uri = AccelerometerBoschImpl.createUri(dataType);
                }
                break;
            case ModuleType.TEMPERATURE:
                uri = TemperatureImpl.createUri(dataType);
                break;
            case ModuleType.GPIO:
                uri = GpioImpl.createUri(dataType);
                break;
            case ModuleType.DATA_PROCESSOR:
                uri = DataProcessorImpl.createUri(
                    dataType, (DataProcessorImpl) mwPrivate.getModules().get(
                    DataProcessor.class), mwPrivate.getFirmwareVersion(),
        mwPrivate.lookupModuleInfo(DATA_PROCESSOR).revision);
        break;
        case ModuleType.SERIAL_PASSTHROUGH:
        uri = SerialPassthroughImpl.createUri(dataType);
        break;
        case ModuleType.SETTINGS:
        uri = SettingsImpl.createUri(dataType);
        break;
        case ModuleType.BAROMETER:
        uri = BarometerBoschImpl.createUri(dataType);
        break;
        case ModuleType.GYRO:
        uri = GyroBmi160Impl.createUri(dataType);
        break;
        case ModuleType.AMBIENT_LIGHT:
        uri = AmbientLightLtr329Impl.createUri(dataType);
        break;
        case ModuleType.MAGNETOMETER:
        uri = MagnetometerBmm150Impl.createUri(dataType);
        break;
        case ModuleType.HUMIDITY:
        uri = HumidityBme280Impl.createUri(dataType);
        break;
        case ModuleType.COLOR_DETECTOR:
        uri = ColorTcs34725Impl.createUri(dataType);
        break;
        case ModuleType.PROXIMITY:
        uri = ProximityTsl2671Impl.createUri(dataType);
        break;
        case ModuleType.SENSOR_FUSION:
        uri = SensorFusionBoschImpl.createUri(dataType);
        break;
        default:
        uri = null;
        break;
        }

        if (uri == null) {
        throw new IllegalStateException("Cannot create uri for data type: " + Util.arrayToHexString(dataType.eventConfig));
        }
        return
        uri;
    }

    static final int NO_DATA_ID = 0xff;

    final Uint8List eventConfig;
    final DataAttributes attributes;
    final DataTypeBase input;
    final List<DataTypeBase> split;

    DataTypeBase.raw(Uint8List config, int offset, int length):
            eventConfig = config,
            input = null,
            split = null,
            attributes = DataAttributes(Uint8List.fromList([length]),1,offset,false);

    DataTypeBase(ModuleType module, int register, DataAttributes attributes, Function split,{int id, DataTypeBase input}):
            this.eventConfig = Uint8List.fromList([module.id,register,id == null ? NO_DATA_ID: id]),
            this.attributes = attributes,
            this.input = input,
            this.split = split();



    Tuple3<int, int, int> eventConfigAsTuple() {
        return Tuple3<int,int,int>(eventConfig[0], eventConfig[1], eventConfig[2]);
    }

    void read(MetaWearBoardPrivate mwPrivate,[Uint8List parameters]) {
      if(parameters == null) {
          if (eventConfig[2] == NO_DATA_ID) {
              mwPrivate.sendCommand(Uint8List.fromList([eventConfig[0], eventConfig[1]]));
          } else {
              mwPrivate.sendCommand(eventConfig);
          }
      }
      else{
          Uint8List command = Uint8List(eventConfig.length + parameters.length);
          command.setAll(0, eventConfig);
          command.setAll(eventConfig.length, parameters);
          mwPrivate.sendCommand(command);
      }
    }


    void markSilent() {
        if ((eventConfig[1] & 0x80) == 0x80) {
            eventConfig[1] |= 0x40;
        }
    }

    void markLive() {
        if ((eventConfig[1] & 0x80) == 0x80) {
            eventConfig[1] &= ~0x40;
        }
    }

    double scale(MetaWearBoardPrivate mwPrivate) {
        return (input == null) ? 1.0 : input.scale(mwPrivate);
    }
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes);
    DataTypeBase dataProcessorCopy(DataTypeBase input, DataAttributes attributes) {
        return copy(input, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, NO_DATA_ID, attributes);
    }
    DataTypeBase dataProcessorStateCopy(DataTypeBase input, DataAttributes attributes) {
        return copy(input, ModuleType.DATA_PROCESSOR, Util.setSilentRead(DataProcessorImpl.STATE), NO_DATA_ID, attributes);
    }

    num convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, num value) {
        return value;
    }
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, Data timestamp, ClassToObject mapper);

    Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch(config.id) {
            case DataProcessorConfig.Buffer.ID:
                return Tuple2(
                    UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(Uint8List(0), 0, 0, false)),
                    dataProcessorStateCopy(this, this.attributes)
                );
            case DataProcessorConfig.Accumulator.ID: {
                DataProcessorConfig.Accumulator casted = (DataProcessorConfig.Accumulator) config;
                DataAttributes attributes= new DataAttributes(new byte[] {casted.output}, (byte) 1, (byte) 0, !casted.counter && this.attributes.signed);

                return new Pair<>(
                    casted.counter ? new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes) : dataProcessorCopy(this, attributes),
                    casted.counter ? new UintData(null, DATA_PROCESSOR, Util.setSilentRead(DataProcessorImpl.STATE), DataTypeBase.NO_DATA_ID, attributes) :
                    dataProcessorStateCopy(this, attributes)
                );
            }
            case DataProcessorConfig.Average.ID:
            case DataProcessorConfig.Delay.ID:
            case DataProcessorConfig.Time.ID:
                return new Pair<>(dataProcessorCopy(this, this.attributes.dataProcessorCopy()), null);
            case DataProcessorConfig.Passthrough.ID:
                return new Pair<>(
                    dataProcessorCopy(this, this.attributes.dataProcessorCopy()),
                    new UintData(DATA_PROCESSOR, Util.setSilentRead(DataProcessorImpl.STATE), DataTypeBase.NO_DATA_ID, new DataAttributes(new byte[] {2}, (byte) 1, (byte) 0, false))
                );
            case DataProcessorConfig.Maths.ID: {
                DataProcessorConfig.Maths casted = (DataProcessorConfig.Maths) config;
                DataTypeBase processor = null;
                switch(casted.op) {
                    case ADD:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySize((byte) 4));
                        break;
                    case MULTIPLY:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySize(Math.abs(casted.rhs) < 1 ? attributes.sizes[0] : 4));
                        break;
                    case DIVIDE:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySize(Math.abs(casted.rhs) < 1 ? 4 : attributes.sizes[0]));
                        break;
                    case SUBTRACT:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySigned(true));
                        break;
                    case ABS_VALUE:
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopySigned(false));
                        break;
                    case MODULUS: {
                        processor = dataProcessorCopy(this, attributes.dataProcessorCopy());
                        break;
                    }
                    case EXPONENT: {
                        processor = new ByteArrayData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                            attributes.dataProcessorCopySize((byte) 4));
                        break;
                    }
                    case LEFT_SHIFT: {
                        processor = new ByteArrayData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                            attributes.dataProcessorCopySize((byte) Math.min(attributes.sizes[0] + (casted.rhs / 8), 4)));
        break;
        }
        case RIGHT_SHIFT: {
        processor = new ByteArrayData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
        attributes.dataProcessorCopySize((byte) Math.max(attributes.sizes[0] - (casted.rhs / 8), 1)));
        break;
        }
        case SQRT: {
        processor = new ByteArrayData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes.dataProcessorCopySigned(false));
        break;
        }
        case CONSTANT:
        DataAttributes attributes = new DataAttributes(new byte[] {4}, (byte) 1, (byte) 0, casted.rhs >= 0);
        processor = attributes.signed ? new IntData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes) :
        new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes);
        break;
        }
        if (processor != null) {
        return new Pair<>(processor, null);
        }
        break;
        }
        case DataProcessorConfig.Pulse.ID: {
        DataProcessorConfig.Pulse casted = (DataProcessorConfig.Pulse) config;
        DataTypeBase processor;
        switch(casted.mode) {
        case WIDTH:
        processor = new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {2}, (byte) 1, (byte) 0, false));
        break;
        case AREA:
        processor = dataProcessorCopy(this, attributes.dataProcessorCopySize((byte) 4));
        break;
        case PEAK:
        processor = dataProcessorCopy(this, attributes.dataProcessorCopy());
        break;
        case ON_DETECT:
        processor = new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));
        break;
        default:
        processor = null;
        }
        if (processor != null) {
        return new Pair<>(processor, null);
        }
        break;
        }
        case DataProcessorConfig.Comparison.ID: {
        DataTypeBase processor = null;
        if (config instanceof DataProcessorConfig.SingleValueComparison) {
        processor = dataProcessorCopy(this, this.attributes.dataProcessorCopy());
        } else if (config instanceof DataProcessorConfig.MultiValueComparison) {
        DataProcessorConfig.MultiValueComparison casted = (DataProcessorConfig.MultiValueComparison) config;
        if (casted.mode == ComparisonOutput.PASS_FAIL || casted.mode == ComparisonOutput.ZONE) {
        processor = new UintData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));
        } else {
        processor = dataProcessorCopy(this, attributes.dataProcessorCopy());
        }
        }
        if (processor != null) {
        return new Pair<>(processor, null);
        }
        break;
        }
        case DataProcessorConfig.Threshold.ID: {
        DataProcessorConfig.Threshold casted = (DataProcessorConfig.Threshold) config;
        switch (casted.mode) {
        case ABSOLUTE:
        return new Pair<>(dataProcessorCopy(this, attributes.dataProcessorCopy()), null);
        case BINARY:
        return new Pair<>(new IntData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
        new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, true)), null);
        }
        break;
        }
        case DataProcessorConfig.Differential.ID: {
        DataProcessorConfig.Differential casted = (DataProcessorConfig.Differential) config;
        switch(casted.mode) {
        case ABSOLUTE:
        return new Pair<>(dataProcessorCopy(this, attributes.dataProcessorCopy()), null);
        case DIFFERENCE:
        throw new IllegalStateException("Differential processor in 'difference' mode must be handled by subclasses");
        case BINARY:
        return new Pair<>(new IntData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, true)), null);
        }
        break;
        }
        case DataProcessorConfig.Packer.ID: {
        DataProcessorConfig.Packer casted = (DataProcessorConfig.Packer) config;
        return new Pair<>(dataProcessorCopy(this, attributes.dataProcessorCopyCopies(casted.count)), null);
        }
        case DataProcessorConfig.Accounter.ID: {
        DataProcessorConfig.Accounter casted = (DataProcessorConfig.Accounter) config;
        return new Pair<>(dataProcessorCopy(this, new DataAttributes(new byte[] {casted.length, attributes.length()}, (byte) 1, (byte) 0, attributes.signed)), null);
        }
        case DataProcessorConfig.Fuser.ID: {
        byte fusedLength = attributes.length();
        DataProcessorConfig.Fuser casted = (DataProcessorConfig.Fuser) config;

        for(byte id: casted.filterIds) {
        fusedLength+= dpModule.activeProcessors.get(id).state.attributes.length();
        }

        return new Pair<>(new ArrayData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {fusedLength}, (byte) 1, (byte) 0, false)), null);
        }
        }
        throw new IllegalStateException("Unable to determine the DataTypeBase object for config: " + Util.arrayToHexString(config.build()));
    }
//
//    protected DataTypeBase[] createSplits() {
//        return null;
//    }
//
//    public DataToken slice(byte offset, byte length) {
//        if (offset < 0) {
//            throw new IndexOutOfBoundsException("offset must be >= 0");
//        }
//        if (offset + length > attributes.length()) {
//            throw new IndexOutOfBoundsException("offset + length is greater than data length (" + attributes.length() + ")");
//        }
//        return new DataTypeBase(eventConfig, offset, length) {
//            @Override
//            public DataTypeBase copy(DataTypeBase input, Module module, byte register, byte id, DataAttributes attributes) {
//                throw new UnsupportedOperationException();
//            }
//
//            @Override
//            public Data createMessage(boolean logData, MetaWearBoardPrivate mwPrivate, byte[] data, Calendar timestamp, DataPrivate.ClassToObject mapper) {
//                throw new UnsupportedOperationException();
//            }
//        };
//    }
}
