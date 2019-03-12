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

import 'package:flutter_metawear/impl/ByteArrayData.dart';

class SerialPassthroughData extends ByteArrayData {

    SerialPassthroughData(int register, int id, int length): super() {
        super(SERIAL_PASSTHROUGH, register, id, new DataAttributes(new byte[] {length}, (byte) 1, (byte) 0, false));
    }

    SerialPassthroughData(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    public DataTypeBase dataProcessorCopy(DataTypeBase input, DataAttributes attributes) {
        return new ByteArrayData(input, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, NO_DATA_ID, attributes);
    }
    public DataTypeBase dataProcessorStateCopy(DataTypeBase input, DataAttributes attributes) {
        return new ByteArrayData(input, DATA_PROCESSOR, Util.setSilentRead(DataProcessorImpl.STATE), NO_DATA_ID, attributes);
    }

    @override
    public DataTypeBase copy(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        return new SerialPassthroughData(input, module, register, id, attributes);
    }

    @override
    public void read(MetaWearBoardPrivate mwPrivate) {
        throw new UnsupportedOperationException("Serial passthrough reads require parameters");
    }

    @override
    public void read(MetaWearBoardPrivate mwPrivate, byte[] parameters) {
    byte[] command= new byte[eventConfig.length - 1 + parameters.length];
    System.arraycopy(eventConfig, 0, command, 0, 2);
    System.arraycopy(parameters, 0, command, 2, parameters.length);

    mwPrivate.sendCommand(command);
    }
}

/**
 * Created by etsai on 10/3/16.
 */
class SerialPassthroughImpl extends ModuleImplBase implements SerialPassthrough {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case I2C_RW:
                return String.format(Locale.US, "i2c[%d]", dataType.eventConfig[2]);
            case SPI_RW:
                return String.format(Locale.US, "spi[%d]", dataType.eventConfig[2]);
            default:
                return null;
        }
    }

    static const int SPI_REVISION= 1;
    static const int I2C_RW = 0x1, SPI_RW = 0x2, DIRECT_I2C_READ_ID = 0xff, DIRECT_SPI_READ_ID = 0xf;
    static const String I2C_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.SerialPassthroughImpl.I2C_PRODUCER_%d",
            SPI_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.SerialPassthroughImpl.SPI_PRODUCER_%d";


    private static class I2cInner implements I2C, Serializable {
        private static final long serialVersionUID = 8518548885863146365L;
        private final byte id;
        transient MetaWearBoardPrivate mwPrivate;

        I2cInner(byte id, byte length, MetaWearBoardPrivate mwPrivate) {
            this.id= id;
            this.mwPrivate = mwPrivate;

            mwPrivate.tagProducer(name(), new SerialPassthroughData(Util.setSilentRead(I2C_RW), id, length));
        }

        void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
            this.mwPrivate = mwPrivate;
        }

        @override
        public void read(byte deviceAddr, byte registerAddr) {
            DataTypeBase i2cProducer= mwPrivate.lookupProducer(name());
            i2cProducer.read(mwPrivate, new byte[]{deviceAddr, registerAddr, id, i2cProducer.attributes.length()});
        }

        @override
        public Task<Route> addRouteAsync(RouteBuilder builder) {
            return mwPrivate.queueRouteBuilder(builder, name());
        }

        @override
        public String name() {
            return String.format(Locale.US, I2C_PRODUCER_FORMAT, id);
        }
    }
    private static class SpiInner implements SPI, Serializable {
        private static final long serialVersionUID = -1781850442398737602L;

        private final byte id;
        transient MetaWearBoardPrivate mwPrivate;

        SpiInner(byte id, byte length, MetaWearBoardPrivate mwPrivate) {
            this.id= id;
            this.mwPrivate = mwPrivate;

            mwPrivate.tagProducer(name(), new SerialPassthroughData(Util.setSilentRead(SPI_RW), id, length));
        }

        void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
            this.mwPrivate = mwPrivate;
        }

        @override
        public SpiParameterBuilder<Void> read() {
            final DataTypeBase spiProducer= mwPrivate.lookupProducer(name());
            return new SpiParameterBuilderInner<Void>((byte) ((spiProducer.attributes.length() - 1) | (id << 4))) {
                @override
                public Void commit() {
                    spiProducer.read(mwPrivate, config);
                    return null;
                }
            };
        }

        @override
        public Task<Route> addRouteAsync(RouteBuilder builder) {
            return mwPrivate.queueRouteBuilder(builder, name());
        }

        @override
        public String name() {
            return String.format(Locale.US, SPI_PRODUCER_FORMAT, id);
        }
    }

    private static abstract class SpiParameterBuilderInner<T> implements SpiParameterBuilder<T> {
        final byte originalLength;
        byte[] config;

        SpiParameterBuilderInner() {
            this.originalLength = 5;
            this.config= new byte[this.originalLength];
        }

        SpiParameterBuilderInner(byte fifthValue) {
            this.originalLength = 6;
            this.config= new byte[this.originalLength];
            config[5] = fifthValue;
        }

        @override
        public SpiParameterBuilder<T> data(byte[] data) {
            byte[] copy = new byte[config.length + data.length];
            System.arraycopy(config, 0, copy, 0, this.originalLength);
            System.arraycopy(data, 0, copy, this.originalLength, data.length);
            config = copy;
            return this;
        }

        @override
        public SpiParameterBuilder<T> slaveSelectPin(byte pin) {
            config[0]= pin;
            return this;
        }

        @override
        public SpiParameterBuilder<T> clockPin(byte pin) {
            config[1]= pin;
            return this;
        }

        @override
        public SpiParameterBuilder<T> mosiPin(byte pin) {
            config[2]= pin;
            return this;
        }

        @override
        public SpiParameterBuilder<T> misoPin(byte pin) {
            config[3]= pin;
            return this;
        }

        @override
        public SpiParameterBuilder<T> lsbFirst() {
            config[4]|= 0x1;
            return this;
        }

        @override
        public SpiParameterBuilder<T> mode(byte mode) {
            config[4]|= (mode << 1);
            return this;
        }

        @override
        public SpiParameterBuilder<T> frequency(SpiFrequency freq) {
            config[4]|= (freq.ordinal() << 3);
            return this;
        }

        @override
        public SpiParameterBuilder<T> useNativePins() {
            config[4]|= (0x1 << 6);
            return this;
        }
    }

    private final Map<Byte, I2C> i2cDataProducers= new ConcurrentHashMap<>();
    private final Map<Byte, SPI> spiDataProducers = new ConcurrentHashMap<>();
    private transient TimedTask<byte[]> readI2cDataTask, readSpiDataTask;

    SerialPassthroughImpl(MetaWearBoardPrivate mwPrivate) {
        super(mwPrivate);
    }

    @override
    public void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for(I2C it: i2cDataProducers.values()) {
            ((I2cInner) it).restoreTransientVars(mwPrivate);
        }

        for(SPI it: spiDataProducers.values()) {
            ((SpiInner) it).restoreTransientVars(mwPrivate);
        }
    }

    @override
    protected void init() {
        readI2cDataTask = new TimedTask<>();
        readSpiDataTask = new TimedTask<>();

        mwPrivate.addDataIdHeader(new Pair<>(SERIAL_PASSTHROUGH.id, Util.setRead(I2C_RW)));
        mwPrivate.addDataHandler(new Tuple3<>(SERIAL_PASSTHROUGH.id, Util.setRead(I2C_RW), DIRECT_I2C_READ_ID), response -> readI2cDataTask.setResult(response));

        mwPrivate.addDataIdHeader(new Pair<>(SERIAL_PASSTHROUGH.id, Util.setRead(SPI_RW)));
        mwPrivate.addDataHandler(new Tuple3<>(SERIAL_PASSTHROUGH.id, Util.setRead(SPI_RW), DIRECT_SPI_READ_ID), response -> readSpiDataTask.setResult(response));
    }

    @override
    public I2C i2c(final byte length, final byte id) {
        if (!i2cDataProducers.containsKey(id)) {
            i2cDataProducers.put(id, new I2cInner(id, length, mwPrivate));
        }

        return i2cDataProducers.get(id);
    }

    @override
    public void writeI2c(byte deviceAddr, byte registerAddr, byte[] data) {
        byte[] params= new byte[data.length + 4];
        params[0]= deviceAddr;
        params[1]= registerAddr;
        params[2]= (byte) 0xff;
        params[3]= (byte) data.length;
        System.arraycopy(data, 0, params, 4, data.length);

        mwPrivate.sendCommand(SERIAL_PASSTHROUGH, I2C_RW, params);
    }

    @override
    public Task<byte[]> readI2cAsync(final byte deviceAddr, final byte registerAddr, final byte length) {
        return readI2cDataTask.execute("Did not receive I2C data within %dms", Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(new byte[] {SERIAL_PASSTHROUGH.id, Util.setRead(I2C_RW), deviceAddr, registerAddr, DIRECT_I2C_READ_ID, length})
        ).onSuccessTask(task -> {
            byte[] response = task.getResult();

            if (response.length > 3) {
                byte[] data = new byte[response.length - 3];
                System.arraycopy(response, 3, data, 0, response.length - 3);
                return Task.forResult(data);
            }
            return Task.forError(new RuntimeException("Error reading I2C data from device or register address.  Response: " + Util.arrayToHexString(response)));
        });
    }

    @override
    public SPI spi(final byte length, final byte id) {
        if (mwPrivate.lookupModuleInfo(Constant.Module.SERIAL_PASSTHROUGH).revision < SPI_REVISION) {
            return null;
        }

        if (!spiDataProducers.containsKey(id)) {
            spiDataProducers.put(id, new SpiInner(id, length, mwPrivate));
        }

        return spiDataProducers.get(id);
    }

    @override
    public SpiParameterBuilder<Void> writeSpi() {
        return mwPrivate.lookupModuleInfo(Constant.Module.SERIAL_PASSTHROUGH).revision >= SPI_REVISION ?
                new SpiParameterBuilderInner<Void>() {
                    @override
                    public Void commit() {
                        mwPrivate.sendCommand(SERIAL_PASSTHROUGH, SPI_RW, config);
                        return null;
                    }
                } :
                null;
    }

    @override
    public SpiParameterBuilder<Task<byte[]>> readSpiAsync(byte length) {
        return new SpiParameterBuilderInner<Task<byte[]>>((byte) ((length - 1) | (DIRECT_SPI_READ_ID << 4))) {
            @override
            public Task<byte[]> commit() {
                return readSpiDataTask.execute("Did not received SPI data within %dms", Constant.RESPONSE_TIMEOUT,
                        () -> mwPrivate.sendCommand(SERIAL_PASSTHROUGH, Util.setRead(SPI_RW), config)
                ).onSuccessTask(task -> {
                    byte[] response = task.getResult();

                    if (response.length > 3) {
                        byte[] data = new byte[response.length - 3];
                        System.arraycopy(response, 3, data, 0, response.length - 3);
                        return Task.forResult(data);
                    }
                    return Task.forError(new RuntimeException("Error reading SPI data from device or register address.  Response: " + Util.arrayToHexString(response)));
                });
            }
        };
    }
}
