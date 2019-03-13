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
import 'package:flutter_metawear/module/AccelerometerMma8452q.dart';
import 'package:tuple/tuple.dart';

import 'package:flutter_metawear/impl/SerialPassthroughImpl.dart';
import 'package:flutter_metawear/impl/BarometerBoschImpl.dart';
import 'package:flutter_metawear/impl/SettingsImpl.dart';
import 'package:flutter_metawear/impl/GyroBmi160Impl.dart';
import 'package:flutter_metawear/impl/AmbientLightLtr329Impl.dart';
import 'package:flutter_metawear/impl/MagnetometerBmm150Impl.dart';
import 'package:flutter_metawear/impl/HumidityBme280Impl.dart';
import 'package:flutter_metawear/impl/ColorTcs34725Impl.dart';
import 'package:flutter_metawear/impl/ProximityTsl2671Impl.dart';
import 'package:flutter_metawear/impl/SensorFusionBoschImpl.dart';
import 'package:flutter_metawear/impl/SwitchImpl.dart';
import 'package:flutter_metawear/impl/TemperatureImpl.dart';
import 'package:flutter_metawear/impl/GpioImpl.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/AccelerometerMma8452qImpl.dart';
import 'package:flutter_metawear/impl/AccelerometerBmi160Impl.dart';
import 'package:flutter_metawear/impl/AccelerometerBoschImpl.dart';

import 'package:flutter_metawear/impl/DataProcessorConfig.dart';

import 'package:flutter_metawear/module/DataProcessor.dart';
import 'package:flutter_metawear/module/Accelerometer.dart';
import 'package:flutter_metawear/module/AccelerometerBmi160.dart';
import 'package:flutter_metawear/module/AccelerometerBma255.dart';

import 'package:flutter_metawear/builder/predicate/PulseOutput.dart';
import 'package:flutter_metawear/builder/filter/DifferentialOutput.dart';
import 'package:flutter_metawear/builder/filter/ThresholdOutput.dart';
import 'dart:math';

class _DataTypeBase extends DataTypeBase{
    _DataTypeBase.raw(Uint8List config, int offset, int length) : super.raw(config, offset, length);

  @override
  DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
      throw UnsupportedError("Unsupported DataTypeBase");
  }

  @override
  Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, Data timestamp, ClassToObject mapper) {
      throw UnsupportedError("Unsupported DataTypeBase");
  }

}

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
                Object module = mwPrivate.getModules()[Accelerometer];
                if (module is AccelerometerMma8452q) {
                    uri = AccelerometerMma8452qImpl.createUri(dataType);
                } else if (module is AccelerometerBmi160) {
                    uri = AccelerometerBmi160Impl.createUri(dataType);
                } else if (module is AccelerometerBma255) {
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
                    dataType, mwPrivate.getModules()[DataProcessor]
                    , mwPrivate.getFirmwareVersion(),
                    mwPrivate
                        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
                        .revision);
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
            throw new Exception("Cannot create uri for data type: " +
                Util.arrayToHexString(dataType.eventConfig));
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
    Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate, Uint8List data, DateTime timestamp, ClassToObject mapper);

    Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch (config.id) {
            case Buffer.ID:
                return Tuple2(
                    UintData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                        new DataAttributes(Uint8List(0), 0, 0, false)),
                    dataProcessorStateCopy(this, this.attributes)
                );
            case Accumulator.ID:
                {
                    Accumulator casted = config as Accumulator;
                    DataAttributes attributes = new DataAttributes(
                        Uint8List.fromList([casted.output]), 1, 0,
                        !casted.counter && this.attributes.signed);

                    return Tuple2(
                        casted.counter ? new UintData(
                            this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
                            attributes) : dataProcessorCopy(this, attributes),
                        casted.counter ? new UintData(null, DATA_PROCESSOR,
                            Util.setSilentRead(DataProcessorImpl.STATE),
                            DataTypeBase.NO_DATA_ID, attributes) :
                        dataProcessorStateCopy(this, attributes)
                    );
                }
            case Average.ID:
            case Delay.ID:
            case Time.ID:
                return Tuple2(dataProcessorCopy(
                    this, this.attributes.dataProcessorCopy()), null);
            case Passthrough.ID:
                return Tuple2(
                    dataProcessorCopy(
                        this, this.attributes.dataProcessorCopy()),
                    new UintData(ModuleType.DATA_PROCESSOR,
                        Util.setSilentRead(DataProcessorImpl.STATE),
                        DataTypeBase.NO_DATA_ID, new DataAttributes(
                            new byte[] {2}, (byte) 1, (byte) 0, false))
                );
            case Maths.ID:
                {
                    Maths casted = config as Maths;
                    DataTypeBase processor = null;
                    switch (casted.op) {
                        case Operation.ADD:
                            processor = dataProcessorCopy(this,
                                attributes.dataProcessorCopySize((byte) 4));
                            break;
                        case Operation.MULTIPLY:
                            processor = dataProcessorCopy(this,
                                attributes.dataProcessorCopySize(
                                    casted.rhs.abs() < 1 ? attributes
                                        .sizes[0] : 4));
                            break;
                        case Operation.DIVIDE:
                            processor = dataProcessorCopy(this,
                                attributes.dataProcessorCopySize(
                                    casted.rhs.abs() < 1 ? 4 : attributes
                                        .sizes[0]));
                            break;
                        case Operation.SUBTRACT:
                            processor = dataProcessorCopy(
                                this, attributes.dataProcessorCopySigned(true));
                            break;
                        case Operation.ABS_VALUE:
                            processor = dataProcessorCopy(this,
                                attributes.dataProcessorCopySigned(false));
                            break;
                        case Operation.MODULUS:
                            {
                                processor = dataProcessorCopy(
                                    this, attributes.dataProcessorCopy());
                                break;
                            }
                        case Operation.EXPONENT:
                            {
                                processor = new ByteArrayData(
                                    this, ModuleType.DATA_PROCESSOR,
                                    DataProcessorImpl.NOTIFY,
                                    attributes.dataProcessorCopySize((byte) 4));
                                break;
                            }
                        case Operation.LEFT_SHIFT:
                            {
                                processor = new ByteArrayData(
                                    this, ModuleType.DATA_PROCESSOR,
                                    DataProcessorImpl.NOTIFY,
                                    attributes.dataProcessorCopySize(
                                        Math.min(attributes.sizes[0] + (
                                        casted.rhs / 8), 4)));
        break;
        }
        case Operation.RIGHT_SHIFT: {
        processor = new ByteArrayData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
        attributes.dataProcessorCopySize((byte) Math.max(attributes.sizes[0] - (casted.rhs / 8), 1)));
        break;
        }
        case Operation.SQRT: {
        processor = new ByteArrayData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes.dataProcessorCopySigned(false));
        break;
        }
        case Operation.CONSTANT:
        DataAttributes attributes = new DataAttributes(new byte[] {4}, (byte) 1, (byte) 0, casted.rhs >= 0);
        processor = attributes.signed ? new IntData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes) :
        new UintData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes);
        break;
        }
        if (processor != null) {
        return Tuple2(processor, null);
        }
        break;
        }
        case Pulse.ID: {
        Pulse casted = config as Pulse;
        DataTypeBase processor;
        switch(casted.mode) {
        case PulseOutput.WIDTH:
        processor = new UintData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {2}, (byte) 1, (byte) 0, false));
        break;
        case PulseOutput.AREA:
        processor = dataProcessorCopy(this, attributes.dataProcessorCopySize((byte) 4));
        break;
        case PulseOutput.PEAK:
        processor = dataProcessorCopy(this, attributes.dataProcessorCopy());
        break;
        case PulseOutput.ON_DETECT:
        processor = new UintData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));
        break;
        default:
        processor = null;
        }
        if (processor != null) {
        return Tuple2(processor, null);
        }
        break;
        }
        case Comparison.ID: {
        DataTypeBase processor = null;
        if (config is SingleValueComparison) {
        processor = dataProcessorCopy(this, this.attributes.dataProcessorCopy());
        } else if (config is MultiValueComparison) {
        MultiValueComparison casted = config as MultiValueComparison;
        if (casted.mode == ComparisonOutput.PASS_FAIL || casted.mode == ComparisonOutput.ZONE) {
        processor = new UintData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false));
        } else {
        processor = dataProcessorCopy(this, attributes.dataProcessorCopy());
        }
        }
        if (processor != null) {
        return Tuple2(processor, null);
        }
        break;
        }
        case Threshold.ID: {
        Threshold casted = config as Threshold;
        switch (casted.mode) {
        case ThresholdOutput.ABSOLUTE:
        return Tuple2(dataProcessorCopy(this, attributes.dataProcessorCopy()), null);
        case ThresholdOutput.BINARY:
        return Tuple2(new IntData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, true)), null);
        }
        break;
        }
        case Differential.ID: {
        Differential casted = config as Differential;
        switch(casted.mode) {
        case DifferentialOutput.ABSOLUTE:
        return Tuple2(dataProcessorCopy(this, attributes.dataProcessorCopy()), null);
        case DifferentialOutput.DIFFERENCE:
        throw new Exception("Differential processor in 'difference' mode must be handled by subclasses");
        case DifferentialOutput.BINARY:
        return Tuple2(new IntData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, true)), null);
        }
        break;
        }
        case Packer.ID: {
        Packer casted = config as Packer;
        return Tuple2(dataProcessorCopy(this, attributes.dataProcessorCopyCopies(casted.count)), null);
        }
        case Accounter.ID: {
        Accounter casted = config as Accounter;
        return Tuple2(dataProcessorCopy(this, new DataAttributes(Uint8List.fromList([casted.length, attributes.length()]), 1, 0, attributes.signed)), null);
        }
        case Fuser.ID: {
        int fusedLength = attributes.length();
        Fuser casted = config as Fuser;

        for(int id in casted.filterIds) {
        fusedLength+= dpModule.activeProcessors.get(id).state.attributes.length();
        }

        return Tuple2(new ArrayData(this, ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, new DataAttributes(new byte[] {fusedLength}, (byte) 1, (byte) 0, false)), null);
        }
        }
        throw new IllegalStateException("Unable to determine the DataTypeBase object for config: " + Util.arrayToHexString(config.build()));
    }

    List<DataTypeBase> createSplits() {
        return null;
    }

    DataToken slice(int offset, int length) {
        if (offset < 0) {
            throw RangeError("offset must be >= 0");
        }
        if (offset + length > attributes.length()) {
            int len = attributes.length();
            throw RangeError("offset + length is greater than data length ($len)");
        }
        return _DataTypeBase.raw(eventConfig, offset, length);
    }
}
