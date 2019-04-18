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

import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/ByteArrayData.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/SerialPassthrough.dart';
import 'dart:typed_data';
import 'package:sprintf/sprintf.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';

class SerialPassthroughData extends ByteArrayData {

    SerialPassthroughData.Default(int register, int id, int length): super(ModuleType.SERIAL_PASSTHROUGH, register, new DataAttributes(Uint8List.fromList([length]), 1, 0, false),id:id);


    SerialPassthroughData(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes):super(module, register, attributes,input:input,id:id);


    DataTypeBase dataProcessorCopy(DataTypeBase input, DataAttributes attributes) {
        return new ByteArrayData(ModuleType.DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes,input: input,id: DataTypeBase.NO_DATA_ID);
    }

    DataTypeBase dataProcessorStateCopy(DataTypeBase input, DataAttributes attributes) {
        return new ByteArrayData(ModuleType.DATA_PROCESSOR, Util.setSilentRead(DataProcessorImpl.STATE), attributes,input: input,id: DataTypeBase.NO_DATA_ID);
    }

    @override
    DataTypeBase copy(DataTypeBase input, ModuleType module, int register, int id, DataAttributes attributes) {
        return new SerialPassthroughData(input, module, register, id, attributes);
    }

    @override
    void read(MetaWearBoardPrivate mwPrivate,[Uint8List parameters]) {
        if(parameters != null){
            Uint8List command= Uint8List(eventConfig.length - 1 + parameters.length);
            command.setAll(0, eventConfig);
            command.setAll(2, parameters);
            mwPrivate.sendCommand(command);
            return;
        }
        throw new Exception("Serial passthrough reads require parameters");
    }
}


class _SpiParameterBuilderInner extends SpiParameterBuilderInner<void> {
    final DataTypeBase _spiProducer;
    final MetaWearBoardPrivate _mwPrivate;

    _SpiParameterBuilderInner(this._spiProducer, this._mwPrivate) : super();

    _SpiParameterBuilderInner.value(int fifthValue, this._spiProducer,
        this._mwPrivate) : super.value(fifthValue);

    @override
    commit() {
        _spiProducer.read(_mwPrivate, config);
        return null;
    }

}

class I2cInner implements I2C{
    final int id;
    MetaWearBoardPrivate mwPrivate;

    I2cInner(this.id, int length, this.mwPrivate) {
        mwPrivate.tagProducer(name(), new SerialPassthroughData.Default(Util.setSilentRead(SerialPassthroughImpl.I2C_RW), id, length));
    }

    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate = mwPrivate;
    }

    @override
    void read(int deviceAddr, int registerAddr) {
        DataTypeBase i2cProducer= mwPrivate.lookupProducer(name());
        i2cProducer.read(mwPrivate, Uint8List.fromList([deviceAddr, registerAddr, id, i2cProducer.attributes.length()]));
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, name());
    }

    @override
    String name() {
        return sprintf(SerialPassthroughImpl.I2C_PRODUCER_FORMAT, id);
    }
}
class SpiInner implements SPI {

    final int id;
    MetaWearBoardPrivate mwPrivate;

    SpiInner(this.id, int length, this.mwPrivate) {
        mwPrivate.tagProducer(name(), new SerialPassthroughData.Default(Util.setSilentRead(SerialPassthroughImpl.SPI_RW), id, length));
    }

    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate = mwPrivate;
    }

    @override
    SpiParameterBuilder<void> read() {
        final DataTypeBase spiProducer= mwPrivate.lookupProducer(name());
        return _SpiParameterBuilderInner.value(((spiProducer.attributes.length() - 1) | (id << 4)), spiProducer, mwPrivate);
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, name());
    }

    @override
    String name() {
        return sprintf(SerialPassthroughImpl.SPI_PRODUCER_FORMAT, id);
    }
}

abstract class SpiParameterBuilderInner<T> implements SpiParameterBuilder<T> {
    final int originalLength;
    Uint8List config;

    SpiParameterBuilderInner(): originalLength = 5, this.config= Uint8List(5);


    SpiParameterBuilderInner.value(int fifthValue): this.originalLength = 6, this.config= Uint8List(6){
        config[5] = fifthValue;
    }

    @override
    SpiParameterBuilder<T> data(Uint8List data) {
        Uint8List copy = Uint8List(config.length + data.length);
        copy.setAll(0, config);
        copy.setAll(originalLength, data);
        config = copy;
        return this;
    }

    @override
    SpiParameterBuilder<T> slaveSelectPin(int pin) {
        config[0]= pin;
        return this;
    }

    @override
    SpiParameterBuilder<T> clockPin(int pin) {
        config[1]= pin;
        return this;
    }

    @override
    SpiParameterBuilder<T> mosiPin(int pin) {
        config[2]= pin;
        return this;
    }

    @override
    SpiParameterBuilder<T> misoPin(int pin) {
        config[3]= pin;
        return this;
    }

    @override
    SpiParameterBuilder<T> lsbFirst() {
        config[4]|= 0x1;
        return this;
    }

    @override
    SpiParameterBuilder<T> mode(int mode) {
        config[4]|= (mode << 1);
        return this;
    }

    @override
    SpiParameterBuilder<T> frequency(SpiFrequency freq) {
        config[4]|= (freq.index << 3);
        return this;
    }

    @override
    SpiParameterBuilder<T> useNativePins() {
        config[4]|= (0x1 << 6);
        return this;
    }
}

class _SpiParameterBuilderInner3 extends SpiParameterBuilderInner {
    final MetaWearBoardPrivate _mwPrivate;

    _SpiParameterBuilderInner3(this._mwPrivate) : super();

    _SpiParameterBuilderInner3.value(int fifthValue, this._mwPrivate)
        : super.value(fifthValue);

    @override
    commit() {
        _mwPrivate.sendCommandForModule(
            ModuleType.SERIAL_PASSTHROUGH, SerialPassthroughImpl.SPI_RW,
            config);
        return null;
    }

}

class _SpiParameterBuilderInner1 extends SpiParameterBuilderInner<Future<Uint8List>> {
    final StreamController<Uint8List> _readControllerSpiController;
    final MetaWearBoardPrivate _mwPrivate;

    _SpiParameterBuilderInner1.value(int fifthValue,
        this._readControllerSpiController, this._mwPrivate)
        : super.value(fifthValue);

    _SpiParameterBuilderInner1(this._readControllerSpiController,
        this._mwPrivate) : super();

    @override
    commit() async {
        Stream<Uint8List> stream = _readControllerSpiController.stream.timeout(
            ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);

        TimeoutException exception = TimeoutException(
            "Did not receive I2C data", ModuleType.RESPONSE_TIMEOUT);
        _mwPrivate.sendCommandForModule(ModuleType.SERIAL_PASSTHROUGH,
            Util.setRead(SerialPassthroughImpl.SPI_RW), config);

        if (await iterator.moveNext().catchError((e) => throw exception,
            test: (e) => e is TimeoutException) == false)
            throw exception;

        Uint8List response = iterator.current;
        await iterator.cancel();

        if (response.length > 0) {
            Uint8List data = Uint8List(response.length - 3);
            data.setAll(0, response.skip(3));
            return data;
        }
        throw Exception(
            "Error reading SPI data from device or register address.  Response: " +
                Util.arrayToHexString(response));
    }
}
/**
 * Created by etsai on 10/3/16.
 */
class SerialPassthroughImpl extends ModuleImplBase implements SerialPassthrough {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case I2C_RW:
                return sprintf("i2c[%d]", dataType.eventConfig[2]);
            case SPI_RW:
                return sprintf("spi[%d]", dataType.eventConfig[2]);
            default:
                return null;
        }
    }

    static const int SPI_REVISION = 1;
    static const int I2C_RW = 0x1,
        SPI_RW = 0x2,
        DIRECT_I2C_READ_ID = 0xff,
        DIRECT_SPI_READ_ID = 0xf;
    static const String I2C_PRODUCER_FORMAT = "com.mbientlab.metawear.impl.SerialPassthroughImpl.I2C_PRODUCER_%d",
        SPI_PRODUCER_FORMAT = "com.mbientlab.metawear.impl.SerialPassthroughImpl.SPI_PRODUCER_%d";


    final Map<int, I2C> i2cDataProducers = Map();
    final Map<int, SPI> spiDataProducers = Map();
    final StreamController<
        Uint8List> _readControllerI2cController = StreamController<Uint8List>();
    final StreamController<
        Uint8List> _readControllerSpiController = StreamController<Uint8List>();

    SerialPassthroughImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);


    @override
    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for (I2C it in i2cDataProducers.values) {
            (it as I2cInner).restoreTransientVars(mwPrivate);
        }

        for (SPI it in spiDataProducers.values) {
            (it as SpiInner).restoreTransientVars(mwPrivate);
        }
    }

    @override
    void init() {
        mwPrivate.addDataIdHeader(
            Tuple2(ModuleType.SERIAL_PASSTHROUGH.id, Util.setRead(I2C_RW)));
        mwPrivate.addDataHandler(Tuple3(
            ModuleType.SERIAL_PASSTHROUGH.id, Util.setRead(I2C_RW),
            DIRECT_I2C_READ_ID), (Uint8List response) =>
            _readControllerI2cController.add(response));

        mwPrivate.addDataIdHeader(
            Tuple2(ModuleType.SERIAL_PASSTHROUGH.id, Util.setRead(SPI_RW)));
        mwPrivate.addDataHandler(Tuple3(
            ModuleType.SERIAL_PASSTHROUGH.id, Util.setRead(SPI_RW),
            DIRECT_SPI_READ_ID), (Uint8List response) =>
            _readControllerSpiController.add(response));
    }

    @override
    I2C i2c(final int length, final int id) {
        if (!i2cDataProducers.containsKey(id)) {
            i2cDataProducers[id] = new I2cInner(id, length, mwPrivate);
        }

        return i2cDataProducers[id];
    }

    @override
    void writeI2c(int deviceAddr, int registerAddr, Uint8List data) {
        Uint8List params = Uint8List(data.length + 4);
        params[0] = deviceAddr;
        params[1] = registerAddr;
        params[2] = 0xff;
        params[3] = data.length;
        params.setAll(4, data);
        mwPrivate.sendCommandForModule(
            ModuleType.SERIAL_PASSTHROUGH, I2C_RW, params);
    }

    @override
    Future<Uint8List> readI2cAsync(final int deviceAddr, final int registerAddr,
        final int length) async {
        Stream<Uint8List> stream = _readControllerI2cController.stream.timeout(
            ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);

        TimeoutException exception = TimeoutException(
            "Did not receive I2C data", ModuleType.RESPONSE_TIMEOUT);
        mwPrivate.sendCommand(Uint8List.fromList([
            ModuleType.SERIAL_PASSTHROUGH.id,
            Util.setRead(I2C_RW),
            deviceAddr,
            registerAddr,
            DIRECT_I2C_READ_ID,
            length
        ]));
        if (await iterator.moveNext().catchError((e) => throw exception,
            test: (e) => e is TimeoutException) == false)
            throw exception;

        Uint8List result = iterator.current;
        if (result.length > 3) {
            Uint8List data = Uint8List(result.length - 3);
            data.setAll(0, result.skip(3));
            return data;
        }
        throw Exception(
            ("Error reading I2C data from device or register address.  Response: " +
                Util.arrayToHexString(result)));
    }

    @override
    SPI spi(final int length, final int id) {
        if (mwPrivate
            .lookupModuleInfo(ModuleType.SERIAL_PASSTHROUGH)
            .revision < SPI_REVISION) {
            return null;
        }

        if (!spiDataProducers.containsKey(id)) {
            spiDataProducers[id] = new SpiInner(id, length, mwPrivate);
        }

        return spiDataProducers[id];
    }

    @override
    SpiParameterBuilder<void> writeSpi() {
        return mwPrivate
            .lookupModuleInfo(ModuleType.SERIAL_PASSTHROUGH)
            .revision >= SPI_REVISION
            ? _SpiParameterBuilderInner3(mwPrivate)
            : null;
    }

    @override
    SpiParameterBuilder<Future<Uint8List>> readSpiAsync(int length) {
        return _SpiParameterBuilderInner1.value(
            (length - 1) | (DIRECT_SPI_READ_ID << 4),
            _readControllerSpiController, mwPrivate);
    }
}
