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

import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/Gpio.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:typed_data';
import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/AsyncDataProducer.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/MilliUnitsUFloatData.dart';

class AnalogInner implements Analog {
    final int pin;
    final String producerNameFormat;
    final MetaWearBoardPrivate mwPrivate;

    AnalogInner(this.mwPrivate,this.pin,this.producerNameFormat);

    @override
    void read([Read read]) {
        if(read == null){
            if (mwPrivate.lookupModuleInfo(ModuleType.GPIO).revision >= GpioImpl.REVISION_ENHANCED_ANALOG) {
                mwPrivate.lookupProducer(name()).read(mwPrivate,Uint8List.fromList([Gpio.UNUSED_READ_PIN, Gpio.UNUSED_READ_PIN, Gpio.UNUSED_READ_DELAY, Gpio.UNUSED_READ_PIN]));
            }
        }
        else{
            if (mwPrivate.lookupModuleInfo(ModuleType.GPIO).revision >= GpioImpl.REVISION_ENHANCED_ANALOG) {
                mwPrivate.lookupProducer(name()).read(mwPrivate, Uint8List.fromList([read.pullup, read.pulldown, (read.delay / 4.0).floor(), read.virtual]));
            }
        }
        mwPrivate.lookupProducer(name()).read(mwPrivate);
    }

      @override
      Future<Route> addRouteAsync(RouteBuilder builder) {

          return mwPrivate.queueRouteBuilder(builder, name());
      }

      @override
      String name() {
          return sprintf(producerNameFormat, [pin]);
      }


}


class _ForcedDataProducer extends ForcedDataProducer{
  @override
  Future<Route> addRouteAsync(RouteBuilder builder) {
    // TODO: implement addRouteAsync
    return null;
  }

  @override
  String name() {
    // TODO: implement name
    return null;
  }

  @override
  void read() {
    // TODO: implement read
  }

}

class _AsyncDataProducer extends AsyncDataProducer{


  @override
  Future<Route> addRouteAsync(RouteBuilder builder) {
    // TODO: implement addRouteAsync
    return null;
  }

  @override
  String name() {
    // TODO: implement name
    return null;
  }

  @override
  void start() {
    // TODO: implement start
  }

  @override
  void stop() {
    // TODO: implement stop
  }

}

class GpioPinImpl implements Pin {
    final int pin;
    final bool virtual;
    final MetaWearBoardPrivate mwPrivate;

    GpioPinImpl(this.pin, this.virtual, this.mwPrivate);

    @override
    bool isVirtual() {
        return virtual;
    }

    @override
    void setChangeType(PinChangeType type) {
        mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.GPIO.id, GpioImpl.PIN_CHANGE, pin, (type.index + 1)
            ]));
    }

    @override
    void setPullMode(PullMode mode) {
        switch (mode) {
            case PullMode.PULL_UP:
                mwPrivate.sendCommand(Uint8List.fromList(
                    [ModuleType.GPIO.id, GpioImpl.PULL_UP_DI, pin
                    ]));
                break;
            case PullMode.PULL_DOWN:
                mwPrivate.sendCommand(Uint8List.fromList(
                    [ModuleType.GPIO.id, GpioImpl.PULL_DOWN_DI, pin
                    ]));
                break;
            case PullMode.NO_PULL:
                mwPrivate.sendCommand(Uint8List.fromList(
                    [ModuleType.GPIO.id, GpioImpl.NO_PULL_DI, pin
                    ]));
                break;
        }
    }

    @override
    void clearOutput() {
        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.GPIO.id, GpioImpl.CLEAR_DO, pin
            ]));
    }

    @override
    void setOutput() {
        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.GPIO.id, GpioImpl.SET_DO, pin
            ]));
    }

    @override
    Analog analogAdc() {
        Analog producer = new AnalogInner(
            mwPrivate, pin, GpioImpl.ADC_PRODUCER_FORMAT);

        if (!mwPrivate.hasProducer(producer.name())) {
            mwPrivate.tagProducer(producer.name(), new UintData(
                ModuleType.GPIO, Util.setSilentRead(GpioImpl.READ_AI_ADC),
                new DataAttributes(Uint8List.fromList([2]), 1, 0, false),
                id: pin));
        }

        return producer;
    }

    @override
    Analog analogAbsRef() {
        Analog producer = new AnalogInner(
            mwPrivate, pin, GpioImpl.ABS_REF_PRODUCER_FORMAT);
        if (!mwPrivate.hasProducer(producer.name())) {
            mwPrivate.tagProducer(producer.name(), new MilliUnitsUFloatData(
                ModuleType.GPIO, Util.setSilentRead(GpioImpl.READ_AI_ABS_REF),
                new DataAttributes(Uint8List.fromList([2]), 1, 0, false),
                id: pin));
        }

        return producer;
    }

    @override
    ForcedDataProducer digital() {
        return null;
//        ForcedDataProducer producer=  new ForcedDataProducer() {
//            @override
//             Task<Route> addRouteAsync(RouteBuilder builder) {
//        return mwPrivate.queueRouteBuilder(builder, name());
//        }
//
//        @override
//        public String name() {
//        return String.format(Locale.US, DIGITAL_PRODUCER_FORMAT, pin);
//        }
//
//        @override
//        public void read() {
//        mwPrivate.lookupProducer(name()).read(mwPrivate);
//        }
//        };
//        if (!mwPrivate.hasProducer(producer.name())) {
//        mwPrivate.tagProducer(producer.name(), new UintData(GPIO, Util.setSilentRead(READ_DI), pin, new DataAttributes(new byte[] {1}, 1, 0, false)));
//        }
//
//        return producer;
    }

    @override
    AsyncDataProducer monitor() {
//        AsyncDataProducer producer=  new AsyncDataProducer() {
//            @override
//            public Task<Route> addRouteAsync(RouteBuilder builder) {
//        return mwPrivate.queueRouteBuilder(builder, name());
//        }
//
//        @override
//        public String name() {
//        return String.format(Locale.US, MONITOR_PRODUCER_FORMAT, pin);
//        }
//
//        @override
//        public void start() {
//        mwPrivate.sendCommand(new byte[]{GPIO.id, PIN_CHANGE_NOTIFY_ENABLE, pin, 1});
//        }
//
//        @override
//        public void stop() {
//        mwPrivate.sendCommand(new byte[]{GPIO.id, PIN_CHANGE_NOTIFY_ENABLE, pin, 0});
//        }
//        };
//        if (!mwPrivate.hasProducer(producer.name())) {
//        mwPrivate.tagProducer(producer.name(), new UintData(GPIO, Util.setSilentRead(READ_DI), pin, new DataAttributes(new byte[] {1}, 1, 0, false)));
//        }
//        mwPrivate.tagProducer(producer.name(), new UintData(GPIO, PIN_CHANGE_NOTIFY, pin, new DataAttributes(new byte[] {1}, 1, 0, false)));
//
//        return producer;
        return null;
    }
}

/**
 * Created by etsai on 9/6/16.
 */
class GpioImpl extends ModuleImplBase implements Gpio {


    static const String ADC_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.GpioImpl.ADC_PRODUCER_\$%d",
        ABS_REF_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.GpioImpl.ABS_REF_PRODUCER_\$%d",
        DIGITAL_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.GpioImpl.DIGITAL_PRODUCER_\$%d",
        MONITOR_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.GpioImpl.MONITOR_PRODUCER_\$%d";
    static const int  REVISION_ENHANCED_ANALOG= 2;
    static const int SET_DO = 1, CLEAR_DO = 2,
        PULL_UP_DI = 3, PULL_DOWN_DI = 4, NO_PULL_DI = 5,
        READ_AI_ABS_REF = 6, READ_AI_ADC = 7, READ_DI = 8,
        PIN_CHANGE = 9, PIN_CHANGE_NOTIFY = 10,
        PIN_CHANGE_NOTIFY_ENABLE = 11;



    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case READ_AI_ABS_REF:
                return sprintf("abs-ref[%d]",[dataType.eventConfig[2]]) ;
            case READ_AI_ADC:
                return sprintf("adc[%d]", [dataType.eventConfig[2]]);
            case READ_DI:
                return sprintf("digital[%d]", [dataType.eventConfig[2]]);
            case PIN_CHANGE_NOTIFY:
                return sprintf("pin-monitor[%d]", [dataType.eventConfig[2]]);
            default:
                return null;
        }
    }


    Map<int, GpioPinImpl> gpioPins;

    GpioImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate);


    @override
    void init()  {
        gpioPins = Map();
    }

    @override
    Pin pin(int index) {
        if (index < 0 || index >= mwPrivate.lookupModuleInfo(ModuleType.GPIO).extra.length) {
            return null;
        }

        if (!gpioPins.containsKey(index)) {
            gpioPins[index] = new GpioPinImpl(index, false, mwPrivate);
        }

        return gpioPins[index];
    }

    @override
    Pin getVirtualPin(int index) {
        if (!gpioPins.containsKey(index)) {
            gpioPins[index]  = new GpioPinImpl(index, true, mwPrivate);
        }
        return gpioPins[index];
    }

}
