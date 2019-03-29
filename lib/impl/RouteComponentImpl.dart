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

import 'dart:math';
import 'dart:typed_data';
import 'dart:core';
import 'dart:collection';

import 'package:flutter_metawear/Subscriber.dart';
import 'package:flutter_metawear/builder/RouteComponent.dart';
import 'package:flutter_metawear/builder/RouteMulticast.dart';
import 'package:flutter_metawear/builder/RouteSplit.dart';
import 'package:flutter_metawear/impl/ColorTcs34725Impl.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/FloatVectorData.dart';
import 'package:flutter_metawear/impl/RouteMulticastImpl.dart';
import 'package:flutter_metawear/impl/RouteSplitImpl.dart';
import 'package:flutter_metawear/impl/Version.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/module/DataProcessor.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/IllegalRouteOperationException.dart';
import 'package:flutter_metawear/builder/predicate/PulseOutput.dart';

import 'package:sprintf/sprintf.dart';
import 'package:tuple/tuple.dart';


enum BranchElement {
    MULTICAST,
    SPLIT
}

class CounterEditorInner extends EditorImplBase implements CounterEditor {

    CounterEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate):super(configObj,source,mwPrivate);

    @override
    void reset() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.DATA_PROCESSOR.id, DataProcessorImpl.STATE, source.eventConfig[2],
        0x00, 0x00, 0x00, 0x00]));
    }

    @override
    void set(int value) {
        Uint8List payload = Uint8List(7);
        ByteData view = ByteData.view(payload.buffer);
        view.setInt8(0, ModuleType.DATA_PROCESSOR.id);
        view.setInt8(1, DataProcessorImpl.STATE);
        view.setInt8(2, source.eventConfig[2]);
        view.setInt32(3, value);
        mwPrivate.sendCommand(payload);
    }
}
class AccumulatorEditorInner extends EditorImplBase implements AccumulatorEditor {

    AccumulatorEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate) : super(configObj,source,mwPrivate);

    @override
    void reset() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.DATA_PROCESSOR.id, DataProcessorImpl.STATE, source.eventConfig[2], 0x00, 0x00, 0x00, 0x00]));
    }

    @override
    void set(num value) {
        int scaledValue = source.convertToFirmwareUnits(mwPrivate, value).floor();

        Uint8List payload = Uint8List(7);
        ByteData view = ByteData.view(payload.buffer);
        view.setInt8(0, ModuleType.DATA_PROCESSOR.id);
        view.setInt8(1, DataProcessorImpl.STATE);
        view.setInt8(2, source.eventConfig[2]);
        view.setInt32(3, scaledValue);

        mwPrivate.sendCommand(payload);
    }
}


class DifferentialEditorInner extends EditorImplBase implements DifferentialEditor {

    DifferentialEditorInner(DataProcessorConfig configObj, DataTypeBase source,
        MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);


    @override
    void modify(num distance) {
        Uint8List newDiff = Uint8List(4);
        ByteData.view(newDiff.buffer).setInt32(0, distance);
        config.setAll(2, newDiff);
        mwPrivate.sendCommandForModule(
            ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,
            source.eventConfig[2]);
    }
}

class PackerEditorInner extends EditorImplBase implements PackerEditor {
    PackerEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate): super(configObj, source, mwPrivate);

    @override
    void clear() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.DATA_PROCESSOR.id, DataProcessorImpl.STATE, source.eventConfig[2]]));
    }
}

class Cache {
    final List<Tuple3<DataTypeBase, Subscriber, bool>> subscribedProducers = List();
    final List<Tuple2<String, Tuple3<DataTypeBase, int, Uint8List>>> feedback = List();
    final List<Tuple2<DataTypeBase, Action>> reactions = List();
    final List<Processor> dataProcessors = List();
    final MetaWearBoardPrivate mwPrivate;
    final Queue<RouteComponentImpl> stashedSignals= ListQueue();
    final Queue<BranchElement> elements = ListQueue();
    final Queue<Tuple2<RouteComponentImpl, List<DataTypeBase>>> splits = ListQueue();
    final Map<String, Processor> taggedProcessors = Map();

    Cache(this.mwPrivate);
}

class AverageEditorInner extends EditorImplBase implements AverageEditor {

    AverageEditorInner(DataProcessorConfig configObj, DataTypeBase source,
        MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);


    @override
    void modify(int samples) {
        config[2] = samples;
        mwPrivate.sendCommandForModule(
            ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,
            source.eventConfig[2]);
    }

    @override
    void reset() {
        mwPrivate.sendCommand(Uint8List.fromList([
            ModuleType.DATA_PROCESSOR.id,
            DataProcessorImpl.STATE,
            source.eventConfig[2]
        ]));
    }
}

class MapEditorInner extends EditorImplBase implements MapEditor {
    MapEditorInner(DataProcessorConfig configObj, DataTypeBase source,
        MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);


    @override
    void modifyRhs(num rhs) {
        num scaledRhs;

        switch (Operation.values[config[2] - 1]) {
            case Operation.ADD:
            case Operation.MODULUS:
            case Operation.SUBTRACT:
                scaledRhs = source.convertToFirmwareUnits(mwPrivate, rhs);
                break;
            case Operation.SQRT:
            case Operation.ABS_VALUE:
                scaledRhs = 0;
                break;
            default:
                scaledRhs = rhs;
        }

        Uint8List newRhs = Uint8List(4);
        ByteData byteData = ByteData.view(newRhs.buffer);
        byteData.setInt32(0, scaledRhs.floor(), Endian.little);

        config.setAll(3, newRhs);

        mwPrivate.sendCommandForModule(
            ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,
            source.eventConfig[2]);
    }
}

class PulseEditorInner extends EditorImplBase implements PulseEditor {

    PulseEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);

    @override
    void modify(num threshold, int samples) {
        Uint8List payload = Uint8List(6);
        ByteData byteData = ByteData.view(payload.buffer);
        byteData.setInt32(0, source.convertToFirmwareUnits(mwPrivate, threshold).floor(),Endian.little);
        byteData.setInt16(4, samples,Endian.little);
        config.setAll(4, payload);
        mwPrivate.sendCommandForModule(ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config, source.eventConfig[2]);
    }
}


class TimeEditorInner extends EditorImplBase implements TimeEditor {
    TimeEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate): super(configObj, source, mwPrivate);


    @override
    void modify(int period) {
        Uint8List payload = Uint8List(4);
        ByteData.view(payload.buffer).setUint32(0, period,Endian.little);
        config.setAll(2, payload);
        mwPrivate.sendCommandForModule(ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,source.eventConfig[2]);
    }
}


class PassthroughEditorInner extends EditorImplBase implements PassthroughEditor {
    PassthroughEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate): super(configObj, source, mwPrivate);


    @override
    void set(int value) {
        Uint8List payload = Uint8List(2);
        ByteData.view(payload.buffer).setInt16(0, value,Endian.little);

        mwPrivate.sendCommandForModule(ModuleType.DATA_PROCESSOR, DataProcessorImpl.STATE, payload, source.eventConfig[2]);
    }

    @override
    void modify(Passthrough type, int value) {
        Uint8List payload= Uint8List(2);
        ByteData.view(payload.buffer).setInt16(0, value);
        config.setAll(2, payload);
        config[1] = type.index & 0x7;
        mwPrivate.sendCommandForModule(ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,source.eventConfig[2]);
    }
}

class SingleValueComparatorEditor extends EditorImplBase implements ComparatorEditor {

    SingleValueComparatorEditor(DataProcessorConfig configObj,
        DataTypeBase source, MetaWearBoardPrivate mwPrivate)
        : super(configObj, source, mwPrivate);


    @override
    void modify(Comparison op, List<num> references) {
        Uint8List payload = Uint8List(6);
        ByteData byteData = ByteData.view(payload.buffer);
        byteData.setInt8(0, op.index);
        byteData.setInt8(1, 0);
        byteData.setInt32(
            2, source.convertToFirmwareUnits(mwPrivate, references[0]).floor());
        config.setAll(2, payload);

        mwPrivate.sendCommandForModule(
            ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,
            source.eventConfig[2]);
    }
}

class MultiValueComparatorEditor extends EditorImplBase implements ComparatorEditor {


    MultiValueComparatorEditor(DataProcessorConfig configObj,
        DataTypeBase source, MetaWearBoardPrivate mwPrivate)
        : super(configObj, source, mwPrivate);

    static void fillReferences(DataTypeBase source,
        MetaWearBoardPrivate mwPrivate, ByteData buffer, int length,
        List<num> references) {
        int index = 0;
        switch (length) {
            case 1:
                for (num it in references) {
                    buffer.setUint8(index,
                        source.convertToFirmwareUnits(mwPrivate, it).floor());
                    index++;
                }
                break;
            case 2:
                for (num it in references) {
                    buffer.setInt16(index,
                        source.convertToFirmwareUnits(mwPrivate, it).floor());
                    index += 2;
                }
                break;
            case 4:
                for (num it in references) {
                    buffer.setInt32(
                        index, source.convertToFirmwareUnits(mwPrivate, it));
                    index += 4;
                }
                break;
        }
    }


    @override
    void modify(Comparison op, List<num> references) {
        Uint8List payload = Uint8List(
            references.length * source.attributes.length());

        fillReferences(source, mwPrivate, ByteData.view(payload.buffer),
            source.attributes.length(), references);

        Uint8List newConfig = Uint8List(
            2 + references.length * source.attributes.length());
        newConfig[0] = config[0];
        newConfig[1] = ((config[1] & ~0x38) | (op.index << 3));
        newConfig.setAll(2, payload);
        config = newConfig;

        mwPrivate.sendCommandForModule(
            ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,
            source.eventConfig[2]);
    }
}

class ThresholdEditorInner extends EditorImplBase implements ThresholdEditor {
    ThresholdEditorInner(DataProcessorConfig configObj, DataTypeBase source, MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);

    @override
    void modify(num threshold, num hysteresis) {
        Uint8List payload = Uint8List(6);
        ByteData byteData = ByteData.view(payload.buffer);
        byteData.setInt32(0, source.convertToFirmwareUnits(mwPrivate, threshold).floor());
        byteData.setInt16(4, source.convertToFirmwareUnits(mwPrivate, hysteresis).floor());

       config.setAll(2, payload);

        mwPrivate.sendCommandForModule(ModuleType.DATA_PROCESSOR, DataProcessorImpl.PARAMETER, config,source.eventConfig[2]);
    }
}

/**
 * Created by etsai on 9/4/16.
 */
class RouteComponentImpl implements RouteComponent {
  static final MULTI_CHANNEL_MATH = Version.fromString("1.1.0"),
      MULTI_COMPARISON_MIN_FIRMWARE = Version.fromString("1.2.3");

  final DataTypeBase source;
  Cache persistantData = null;

  RouteComponentImpl(this.source, [RouteComponentImpl original])
      : this.persistantData = original == null ? null : original.persistantData;

//    RouteComponentImpl(DataTypeBase source, RouteComponentImpl original) {
//        this.source= source;
//        this.persistantData= original.persistantData;
//    }

  void setup(Cache original) {
    this.persistantData = original;
  }

  @override
  RouteMulticast multicast() {
    persistantData.elements.add(BranchElement.MULTICAST);
    persistantData.stashedSignals.addLast(this);
    return RouteMulticastImpl(this);
  }

  @override
  RouteComponent to() {
    try {
      return persistantData.stashedSignals.last;
    } on StateError {
      throw StateError("No multicast source to direct data from");
    }
  }

  @override
  RouteSplit split() {
    if (source.split == null) {
      throw new IllegalRouteOperationException(sprintf(
          "Cannot split source data signal '%s'",
          source.runtimeType.toString()));
    }

    persistantData.elements.add(BranchElement.SPLIT);
    persistantData.splits.add(Tuple2(this, source.split));
    return RouteSplitImpl(this);
  }

  @override
  RouteComponent index(int i) {
    try {
      return new RouteComponentImpl(persistantData.splits.last.item2[i], this);
    } on RangeError {
      throw new IllegalRouteOperationException(
          "Index on split data out of bounds");
    }
  }

  @override
  RouteComponent end() {
    try {
      switch (persistantData.elements.removeLast()) {
        case BranchElement.MULTICAST:
          persistantData.stashedSignals.removeLast();
          return persistantData.stashedSignals.isEmpty ? null : persistantData
              .stashedSignals.last;
        case BranchElement.SPLIT:
          persistantData.splits.last;
          return persistantData.splits.isEmpty ? null : persistantData.splits
              .last.item1;
        default:
          throw Exception("Only here so the compiler doesn't complain");
      }
    } on StateError {
      throw new IllegalRouteOperationException(
          "No multicast nor split to end the branch on");
    }
  }

  @override
  RouteComponent name(String name) {
    if (persistantData.taggedProcessors.containsKey(name)) {
      throw new IllegalRouteOperationException(
          sprintf("Duplicate processor key \'%s\' found", [name]));
    }

    persistantData.taggedProcessors[name] = persistantData.dataProcessors.last;
    return this;
  }

  @override
  RouteComponent stream(Subscriber subscriber) {
    if (source.attributes.length() > 0) {
      source.markLive();
      persistantData.subscribedProducers.add(Tuple3(source, subscriber, false));
      return this;
    }
    throw new IllegalRouteOperationException("Cannot subscribe to null data");
  }

  @override
  RouteComponent log(Subscriber subscriber) {
    if (source.attributes.length() > 0) {
      persistantData.subscribedProducers.add(
          new Tuple3(source, subscriber, true));
      return this;
    }
    throw new IllegalRouteOperationException("Cannot log null data");
  }

  @override
  RouteComponent react(Action action) {
    persistantData.reactions.add(Tuple2(source, action));
    return this;
  }

  @override
  RouteComponent buffer() {
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          "Cannot apply \'buffer\' filter to null data");
    }

    DataProcessorConfig config = Buffer(source.attributes.length());
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);
    return postCreate(next.item2,
        new NullEditor(config, next.item1, persistantData.mwPrivate));
  }


  RouteComponentImpl createReducer(bool counter) {
    if (!counter) {
      if (source.attributes.length() <= 0) {
        throw new IllegalRouteOperationException("Cannot accumulate null data");
      }
      if (source.attributes.length() > 4) {
        throw new IllegalRouteOperationException(
            "Cannot accumulate data longer than 4 bytes");
      }
    }

    final int output = 4;
    DataProcessorConfig config = new Accumulator(
        counter, output, source.attributes.length());
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    EditorImplBase editor = counter ?
    new CounterEditorInner(config, next.item1, persistantData.mwPrivate) :
    new AccumulatorEditorInner(config, next.item1, persistantData.mwPrivate);

    return postCreate(next.item2, editor);
  }

  @override
  RouteComponent count() {
    return createReducer(true);
  }

  @override
  RouteComponent accumulate() {
    return createReducer(false);
  }

  RouteComponent applyAverager(int nSamples, bool hpf, String name) {
    bool hasHpf = persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision >= DataProcessorImpl.HPF_REVISION;
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          sprintf("Cannot apply %s filter to null data", name));
    }
    if (source.attributes.length() > 4 && !hasHpf) {
      throw new IllegalRouteOperationException(
          sprintf("Cannot apply %s filter to data longer than 4 bytes", name));
    }
    if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
      throw new IllegalRouteOperationException(
          sprintf("Cannot apply  %s filter to sensor fusion data", name));
    }

    DataProcessorConfig config = new Average(
        source.attributes, nSamples, hpf, hasHpf);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new AverageEditorInner(config, next.item1, persistantData.mwPrivate));
  }

  @override
  RouteComponent highpass(int nSamples) {
    if (persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision < DataProcessorImpl.HPF_REVISION) {
      throw new IllegalRouteOperationException(
          "High pass filtering not supported on this firmware version");
    }
    return applyAverager(nSamples, true, "high-pass");
  }

  @override
  RouteComponent lowpass(int nSamples) {
    return applyAverager(nSamples, false, "low-pass");
  }

  @override
  RouteComponent average(int nSamples) {
    return lowpass(nSamples);
  }

  @override
  RouteComponent delay(int samples) {
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException("Cannot delay null data");
    }

    bool expanded = persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision >= DataProcessorImpl.EXPANDED_DELAY;
    int maxLength = expanded ? 16 : 4;
    if (source.attributes.length() > maxLength) {
      throw new IllegalRouteOperationException(sprintf(
          "Firmware does not support delayed data longer than %d bytes",
          maxLength));
    }

    DataProcessorConfig config = new Delay(
        expanded, source.attributes.length(), samples);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new NullEditor(config, next.item1, persistantData.mwPrivate));
  }

  RouteComponentImpl createCombiner(DataTypeBase source, bool rss) {
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          sprintf("Cannot apply \'%s\' to null data", !rss ? "rms" : "rss"));
    } else if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
      throw new IllegalRouteOperationException(sprintf(
          "Cannot apply \'%s\' to sensor fusion data", !rss ? "rms" : "rss"));
    }

    // assume sizes array is filled with the same value
    DataProcessorConfig config = new Combiner(source.attributes, rss);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);
    return postCreate(next.item2,
        new NullEditor(config, next.item1, persistantData.mwPrivate));
  }

  @override
  RouteComponent map(FunctionBuilder fn) {
    if (fn.handler is Function1) {
      switch (fn.handler as Function1) {
        case Function1.ABS_VALUE:
          return applyMath(Operation.ABS_VALUE, 0);
        case Function1.RMS:
          if (source is FloatVectorData || source is ColorAdcData) {
            return createCombiner(source, false);
          }
          return null;
        case Function1.RSS:
          if (source is FloatVectorData || source is ColorAdcData) {
            return createCombiner(source, true);
          }
          return null;
        case Function1.SQRT:
          return applyMath(Operation.SQRT, 0);
      }
    }
    else if (fn.handler is Function2) {
      RouteComponent route = null;
      if (fn.target is num || fn.target is List<String>)
        throw Exception("target has to be either a List<String> or num");
      num rhs = fn.target is num ? fn.target : 0;

      switch (fn.handler as Function2) {
        case Function2.ADD:
          route = applyMath(Operation.ADD, rhs);
          break;
        case Function2.MULTIPLY:
          route = applyMath(Operation.MULTIPLY, rhs);
          break;
        case Function2.DIVIDE:
          route = applyMath(Operation.DIVIDE, rhs);
          break;
        case Function2.MODULUS:
          route = applyMath(Operation.MODULUS, rhs);
          break;
        case Function2.EXPONENT:
          route = applyMath(Operation.EXPONENT, rhs);
          break;
        case Function2.LEFT_SHIFT:
          route = applyMath(Operation.LEFT_SHIFT, rhs);
          break;
        case Function2.RIGHT_SHIFT:
          route = applyMath(Operation.RIGHT_SHIFT, rhs);
          break;
        case Function2.SUBTRACT:
          route = applyMath(Operation.SUBTRACT, rhs);
          break;
        case Function2.CONSTANT:
          route = applyMath(Operation.CONSTANT, rhs);
          break;
      }
      if (fn.target is List<String>) {
        for (String key in fn.target as List<String>) {
          persistantData.feedback.add(Tuple2(
              key, Tuple3((route as RouteComponentImpl).source, 4,
              persistantData.dataProcessors.last.editor.config)));
        }
      }
      return route;
    }
  }

  RouteComponent applyMath(Operation op, num rhs) {
    bool multiChnlMath = persistantData.mwPrivate.getFirmwareVersion()
        .compareTo(MULTI_CHANNEL_MATH) >= 0;

    if (!multiChnlMath && source.attributes.length() > 4) {
      throw new IllegalRouteOperationException(
          "Cannot apply math operations on multi-channel data for firmware prior to " +
              MULTI_CHANNEL_MATH.toString());
    }

    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          "Cannot apply math operations to null data");
    }

    if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
      throw new IllegalRouteOperationException(
          "Cannot apply math operations to sensor fusion data");
    }

    num scaledRhs;
    switch (op) {
      case Operation.ADD:
      case Operation.MODULUS:
      case Operation.SUBTRACT:
        scaledRhs =
            source.convertToFirmwareUnits(persistantData.mwPrivate, rhs);
        break;
      case Operation.SQRT:
      case Operation.ABS_VALUE:
        scaledRhs = 0;
        break;
      default:
        scaledRhs = rhs;
    }

    Maths config = Maths(
        source.attributes, multiChnlMath, op, scaledRhs.floor());
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);
    config.output = next.item1.attributes.sizes[0];
    return postCreate(next.item2,
        new MapEditorInner(config, next.item1, persistantData.mwPrivate));
  }

  @override
  RouteComponent resample(int period) {
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          "Cannot limit frequency of null data");
    }

    bool hasTimePassthrough = persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision >= DataProcessorImpl.TIME_PASSTHROUGH_REVISION;
    if (!hasTimePassthrough &&
        source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
      throw new IllegalRouteOperationException(
          "Cannot limit frequency of sensor fusion data");
    }

    DataProcessorConfig config = new Time(
        source.attributes.length(), (hasTimePassthrough ? 2 : 0), period);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new TimeEditorInner(config, next.item1, persistantData.mwPrivate));
  }

  @override
  RouteComponent limit(Passthrough type, int value) {
    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException("Cannot limit null data");
    }

    DataProcessorConfig config = PassthroughConfig(type, value);

    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);
    return postCreate(next.item2, new PassthroughEditorInner(
        config, next.item1, persistantData.mwPrivate));
  }


  @override
  RouteComponent find(PulseOutput output, num threshold, int samples) {
    if (source.attributes.length() > 4) {
      throw new IllegalRouteOperationException(
          "Cannot find pulses for data longer than 4 bytes");
    }

    if (source.attributes.length() <= 0) {
      throw new IllegalRouteOperationException(
          "Cannot find pulses for null data");
    }

    if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
      throw new IllegalRouteOperationException(
          "Cannot find pulses for sensor fusion data");
    }

    DataProcessorConfig config = new Pulse(source.attributes.length(),
        source.convertToFirmwareUnits(persistantData.mwPrivate, threshold)
            .floor(), samples, output);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config,
        persistantData.mwPrivate
            .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new PulseEditorInner(config, next.item1, persistantData.mwPrivate));
  }

  RouteComponent filter(Filter filter) {
    if (filter is ThresholdFilter) {
      ThresholdFilter item = filter as ThresholdFilter;

      if (source.attributes.length() > 4) {
        throw new IllegalRouteOperationException(
            "Cannot use threshold filter on data longer than 4 bytes");
      }

      if (source.attributes.length() <= 0) {
        throw new IllegalRouteOperationException(
            "Cannot use threshold filter on null data");
      }

      if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
        throw new IllegalRouteOperationException(
            "Cannot use threshold filter on sensor fusion data");
      }

      num firmwareValue = source.convertToFirmwareUnits(
          persistantData.mwPrivate, item.threshold),
          firmwareHysteresis = source.convertToFirmwareUnits(
              persistantData.mwPrivate, item.hysteresis);

      DataProcessorConfig config = new Threshold(
          source.attributes.length(), source.attributes.signed, item.output,
          firmwareValue.floor(), firmwareHysteresis.floor());
      Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
          config, persistantData.mwPrivate
          .getModules()[DataProcessor] as DataProcessorImpl);
      return postCreate(next.item2, new ThresholdEditorInner(
          config, next.item1, persistantData.mwPrivate));
    }
    else if (filter is ComparisonFilter) {
      ComparisonFilter item = filter as ComparisonFilter;
      List<num> references = item.target is List<num> ? item
          .target as List<num> : [0];
      RouteComponent routeComponent = null;

      if (source.attributes.length() > 4) {
        throw new IllegalRouteOperationException(
            "Cannot compare data longer than 4 bytes");
      }

      if (source.attributes.length() <= 0) {
        throw new IllegalRouteOperationException(
            "Cannot compare null data");
      }

      if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
        throw new IllegalRouteOperationException(
            "Cannot compare sensor sensor fusion data");
      }

      if (persistantData.mwPrivate.getFirmwareVersion().compareTo(
          MULTI_COMPARISON_MIN_FIRMWARE) < 0) {
        bool signed = source.attributes.signed ||
            references[0].toDouble() < 0;
        final num scaledReference = source.convertToFirmwareUnits(
            persistantData.mwPrivate, references[0]);

        DataProcessorConfig config = new SingleValueComparison(
            signed, item.op, scaledReference.floor());
        Tuple2<DataTypeBase, DataTypeBase> next = source
            .dataProcessorTransform(config, persistantData.mwPrivate
            .getModules()[DataProcessor] as DataProcessorImpl);
        routeComponent = postCreate(next.item2,
            new SingleValueComparatorEditor(
                config, next.item1, persistantData.mwPrivate));
      }
      else {
        bool anySigned = false;
        List<num> scaled = List<num>(references.length);
        for (int i = 0; i < references.length; i++) {
          anySigned |= references[i].toDouble() < 0;
          scaled[i] = source.convertToFirmwareUnits(
              persistantData.mwPrivate, references[i]);
        }
        bool signed = source.attributes.signed || anySigned;

        DataProcessorConfig config = MultiValueComparison(
            signed, source.attributes.length(), item.op,
            item.comparisonOutput, scaled);
        Tuple2<DataTypeBase, DataTypeBase> next = source
            .dataProcessorTransform(config, persistantData.mwPrivate
            .getModules()[DataProcessor] as DataProcessorImpl);

        routeComponent = postCreate(next.item2,
            new MultiValueComparatorEditor(
                config, next.item1, persistantData.mwPrivate));
      }
      if (routeComponent != null && item.target is List<String>) {
        for (String key in item.target as List<String>) {
          persistantData.feedback.add(Tuple2(
              key,
              Tuple3(
                  (routeComponent as RouteComponentImpl).source,
                  persistantData.mwPrivate.getFirmwareVersion()
                      .compareTo(MULTI_COMPARISON_MIN_FIRMWARE) < 0
                      ? 5
                      : 3,
                  persistantData.dataProcessors.last.editor.config
              )
          ));
        }
      }
      return routeComponent;
    }
    else if (filter is DifferentialFilter) {
      DifferentialFilter item = filter as DifferentialFilter;

      if (source.attributes.length() > 4) {
        throw new IllegalRouteOperationException(
            "Cannot use differential filter for data longer than 4 bytes");
      }

      if (source.attributes.length() <= 0) {
        throw new IllegalRouteOperationException(
            "Cannot use differential filter for null data");
      }

      if (source.eventConfig[0] == ModuleType.SENSOR_FUSION.id) {
        throw new IllegalRouteOperationException(
            "Cannot use differential filter on sensor fusion data");
      }

      num firmwareUnits = source.convertToFirmwareUnits(
          persistantData.mwPrivate, item.distance);
      DataProcessorConfig config = new Differential(
          source.attributes.length(), source.attributes.signed, item.op,
          firmwareUnits.floor());

      Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
          config, persistantData.mwPrivate
          .getModules()[DataProcessor] as DataProcessorImpl);

      return postCreate(next.item2, new DifferentialEditorInner(
          config, next.item1, persistantData.mwPrivate));
    }
    throw Exception("Unknown Filter");
  }

  RouteComponentImpl postCreate(DataTypeBase state, EditorImplBase editor) {
    persistantData.dataProcessors.add(new Processor(state, editor));
    return new RouteComponentImpl(editor.source, this);
  }

  @override
  RouteComponent pack(int count) {
    if (persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision < DataProcessorImpl.ENHANCED_STREAMING_REVISION) {
      throw new IllegalRouteOperationException(
          "Current firmware does not support data packing");
    }

    if (source.attributes.length() * count + 3 > ModuleType.MAX_BTLE_LENGTH) {
      throw new IllegalRouteOperationException(
          "Not enough space in the ble packet to pack " + count.toString() +
              " data samples");
    }

    DataProcessorConfig config = new Packer(source.attributes.length(), count);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new PackerEditorInner(config, next.item1, persistantData.mwPrivate));
  }


  @override
  RouteComponent account([AccountType type = AccountType.TIME]) {
    if (persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision < DataProcessorImpl.ENHANCED_STREAMING_REVISION) {
      throw new IllegalRouteOperationException(
          "Current firmware does not support data accounting");
    }

    final int size = (type == AccountType.TIME ? 4 : min(
        4, ModuleType.MAX_BTLE_LENGTH - 3 - source.attributes.length()));
    if (type == AccountType.TIME &&
        source.attributes.length() + size + 3 > ModuleType.MAX_BTLE_LENGTH ||
        type == AccountType.COUNT && size < 0) {
      throw new IllegalRouteOperationException(
          "Not enough space left in the ble packet to add accounter information");
    }

    DataProcessorConfig config = Accounter(size, type);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config, persistantData.mwPrivate
        .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new NullEditor(config, next.item1, persistantData.mwPrivate));
  }

  @override
  RouteComponent fuse(List<String> bufferNames) {
    if (persistantData.mwPrivate
        .lookupModuleInfo(ModuleType.DATA_PROCESSOR)
        .revision < DataProcessorImpl.FUSE_REVISION) {
      throw new IllegalRouteOperationException(
          "Current firmware does not support data fusing");
    }

    DataProcessorConfig config = Fuser(bufferNames);
    Tuple2<DataTypeBase, DataTypeBase> next = source.dataProcessorTransform(
        config,
        persistantData.mwPrivate
            .getModules()[DataProcessor] as DataProcessorImpl);

    return postCreate(next.item2,
        new NullEditor(config, next.item1, persistantData.mwPrivate));
  }
}

