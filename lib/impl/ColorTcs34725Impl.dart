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


import 'package:flutter_metawear/Data.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataPrivate.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/ColorTcs34725.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';

import 'package:sprintf/sprintf.dart';


class ColorAdcData extends DataTypeBase {
  ColorAdcData.Default() : super(
      ModuleType.COLOR_DETECTOR, Util.setSilentRead(ColorTcs34725Impl.ADC),
      DataAttributes(Uint8List.fromList([2, 2, 2, 2]), 1, 0, false));


  ColorAdcData(DataTypeBase input, ModuleType module, int register, int id,
      DataAttributes attributes)
      : super(module, register, attributes, input: input, id: id);

  @override
  DataTypeBase copy(DataTypeBase input, ModuleType module, int register,
      int id, DataAttributes attributes) {
    return ColorAdcData(input, module, register, id, attributes);
  }

  @override
  Data createMessage(bool logData, MetaWearBoardPrivate mwPrivate,
      Uint8List data, DateTime timestamp, T Function<T>() apply) {
    ByteData byteData = ByteData.view(data.buffer);

    final ColorAdc wrapper = ColorAdc(
        byteData.getInt16(0, Endian.little) & 0xffff,
        byteData.getInt16(2, Endian.little) & 0xffff,
        byteData.getInt16(4, Endian.little) & 0xffff,
        byteData.getInt16(6, Endian.little) & 0xffff
    );

    return DataPrivate2(timestamp, data, apply, () => 1.0, <T>() {
      if (T is ColorAdc)
        return wrapper as T;
    });
  }

  @override
  List<DataTypeBase> createSplits() {
    return [
      ColorTcs34725Impl.createAdcUintDataProducer(0),
      ColorTcs34725Impl.createAdcUintDataProducer(2),
      ColorTcs34725Impl.createAdcUintDataProducer(4),
      ColorTcs34725Impl.createAdcUintDataProducer(6)
    ];
  }


  @override
  Tuple2<DataTypeBase, DataTypeBase> dataProcessorTransform(
      DataProcessorConfig config, DataProcessorImpl dpModule) {
    switch (config.id) {
      case Combiner.ID:
        {
          DataAttributes attributes = new DataAttributes(
              Uint8List.fromList([this.attributes.sizes[0]]), 1, 0, false);
          return Tuple2(new UintData(
              ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY,
              attributes, input: this), null);
        }
    }

    return super.dataProcessorTransform(config, dpModule);
  }

}

class _ConfigEditor extends ConfigEditor {
  int aTime = 0xff;
  Gain _gain = Gain.TCS34725_1X;
  int illuminate = 0;
  final MetaWearBoardPrivate _mwPrivate;

  _ConfigEditor(this._mwPrivate);


  @override
  ConfigEditor integrationTime(double time) {
    aTime = (256.0 - time / 2.4).floor();
    return this;
  }

  @override
  ConfigEditor gain(Gain gain) {
    this._gain = gain;
    return this;
  }

  @override
  ConfigEditor enableIlluminatorLed() {
    illuminate = 1;
    return this;
  }

  @override
  void commit() {
    _mwPrivate.sendCommand(Uint8List.fromList([
      ModuleType.COLOR_DETECTOR.id,
      ColorTcs34725Impl.MODE,
      aTime,
      _gain.index,
      illuminate
    ]));
  }
}

class _ColorAdcDataProducer extends ColorAdcDataProducer {
  final MetaWearBoardPrivate _mwPrivate;

  _ColorAdcDataProducer(this._mwPrivate);

  @override
  void read() {
    _mwPrivate.lookupProducer(ColorTcs34725Impl.ADC_PRODUCER).read(_mwPrivate);
  }

  @override
  String clearName() {
    return ColorTcs34725Impl.ADC_CLEAR_PRODUCER;
  }

  @override
  String redName() {
    return ColorTcs34725Impl.ADC_RED_PRODUCER;
  }

  @override
  String greenName() {
    return ColorTcs34725Impl.ADC_GREEN_PRODUCER;
  }

  @override
  String blueName() {
    return ColorTcs34725Impl.ADC_BLUE_PRODUCER;
  }

  @override
  Future<Route> addRouteAsync(RouteBuilder builder) {
    return _mwPrivate.queueRouteBuilder(
        builder, ColorTcs34725Impl.ADC_PRODUCER);
  }

  @override
  String name() {
    return ColorTcs34725Impl.ADC_PRODUCER;
  }
}

/**
 * Created by etsai on 9/19/16.
 */
class ColorTcs34725Impl extends ModuleImplBase implements ColorTcs34725 {
  static String createUri(DataTypeBase dataType) {
    switch (Util.clearRead(dataType.eventConfig[1])) {
      case ADC:
        return dataType.attributes.length() > 2 ? "color" : sprintf(
            "color[%d]", [dataType.attributes.offset >> 1]);
      default:
        return null;
    }
  }

  static const String ADC_PRODUCER = "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_PRODUCER",
      ADC_CLEAR_PRODUCER = "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_CLEAR_PRODUCER",
      ADC_RED_PRODUCER = "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_RED_PRODUCER",
      ADC_GREEN_PRODUCER = "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_GREEN_PRODUCER",
      ADC_BLUE_PRODUCER = "com.mbientlab.metawear.impl.ColorTcs34725Impl.ADC_BLUE_PRODUCER";
  static const int ADC = 1,
      MODE = 2;

  static UintData createAdcUintDataProducer(int offset) {
    return new UintData(ModuleType.COLOR_DETECTOR, Util.setSilentRead(ADC),
        DataAttributes(Uint8List.fromList([2]), 1, offset, true));
  }

  ColorAdcDataProducer adcProducer;

  ColorTcs34725Impl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate) {
    DataTypeBase adcProducer = ColorAdcData.Default();
    this.mwPrivate.tagProducer(ADC_PRODUCER, adcProducer);
    this.mwPrivate.tagProducer(ADC_CLEAR_PRODUCER, adcProducer.split[0]);
    this.mwPrivate.tagProducer(ADC_RED_PRODUCER, adcProducer.split[1]);
    this.mwPrivate.tagProducer(ADC_GREEN_PRODUCER, adcProducer.split[2]);
    this.mwPrivate.tagProducer(ADC_BLUE_PRODUCER, adcProducer.split[3]);
  }

  @override
  ConfigEditor configure() {
    return _ConfigEditor(mwPrivate);
  }

  @override
  ColorAdcDataProducer adc() {
    if (adcProducer == null) {
      adcProducer = _ColorAdcDataProducer(mwPrivate);
    }
    return adcProducer;
  }
}
