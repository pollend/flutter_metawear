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
import 'package:flutter_metawear/impl/AccelerometerBoschImpl.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/module/AccelerometerBma255.dart' as AccelerometerBma255;

class _ConfigEditor extends AccelerometerBma255.ConfigEditor{
    AccelerometerBma255.OutputDataRate odr= AccelerometerBma255.OutputDataRate.ODR_125HZ;
    AccRange ar= AccRange.AR_2G;

    @override
     AccelerometerBma255.ConfigEditor odr(OutputDataRate odr) {
        this.odr= odr;
        return this;
    }

    @override
     AccelerometerBma255.ConfigEditor range(AccRange ar) {
        this.ar= ar;
        return this;
    }

    @override
     AccelerometerBma255.ConfigEditor odr(float odr) {
        List<double> frequencies= OutputDataRate.frequencies();
        int pos= Util.closestIndex(frequencies, odr);

        return odr(OutputDataRate.values()[pos]);
    }

    @override
     AccelerometerBma255.ConfigEditor range(float fsr) {
        float[] ranges= AccRange.ranges();
        int pos= Util.closestIndex(ranges, fsr);

        return range(AccRange.values()[pos]);
    }

    @override
    void commit() {
        accDataConfig[0]&= 0xe0;
        accDataConfig[0]|= odr.ordinal() + 8;

        accDataConfig[1]&= 0xf0;
        accDataConfig[1]|= ar.bitmask;

        mwPrivate.sendCommand(ACCELEROMETER, DATA_CONFIG, accDataConfig);
    }
}

class Bma255FlatDataProducer extends BoschFlatDataProducer implements AccelerometerBma255.FlatDataProducer {
    @override
    public AccelerometerBma255.FlatConfigEditor configure() {
        return new AccelerometerBma255.FlatConfigEditor() {
            private FlatHoldTime holdTime = FlatHoldTime.FHT_512_MS;
            private float theta = 5.6889f;

        @override
        public AccelerometerBma255.FlatConfigEditor holdTime(FlatHoldTime time) {
        holdTime = time;
        return this;
        }

        @override
        public AccelerometerBma255.FlatConfigEditor holdTime(float time) {
        return holdTime(FlatHoldTime.values()[Util.closestIndex(FlatHoldTime.delays(), time)]);
        }

        @override
        public AccelerometerBma255.FlatConfigEditor flatTheta(float angle) {
        theta = angle;
        return this;
        }

        @override
        public void commit() {
        writeFlatConfig(holdTime.ordinal(), theta);
        }
    };
    }
}

/**
 * Created by etsai on 9/1/16.
 */
class AccelerometerBma255Impl extends AccelerometerBoschImpl implements AccelerometerBma255.AccelerometerBma255 {

    static const int IMPLEMENTATION = 0x3;
    static Uint8List DEFAULT_MOTION_CONFIG = Uint8List.fromList([0x00, 0x14, 0x14]);

    static final Uint8List accDataConfig= Uint8List.fromList([0x0b, 0x03]);

    AsyncDataProducer _flat, _lowhigh, _noMotion, _slowMotion, _anyMotion;
//    TimedTask<Uint8List> _pullConfigTask;

    AccelerometerBma255Impl(MetaWearBoardPrivate mwPrivate): super(mwPrivate);


    @override
    void init() {
        mwPrivate.addResponseHandler(new Pair<>(ACCELEROMETER.id, Util.setRead(DATA_CONFIG)), response -> pullConfigTask.setResult(response));
    }

    @override
     double getAccDataScale() {
        return AccRange.bitMaskToRange((byte) (accDataConfig[1] & 0xf)).scale;
    }

    @override
     int getSelectedAccRange() {
        return AccRange.bitMaskToRange((byte) (accDataConfig[1] & 0xf)).ordinal();
    }

    @override
     int getMaxOrientHys() {
        return 0x7;
    }

    @override
    AccelerometerBma255.ConfigEditor configure() {
        return new AccelerometerBma255.ConfigEditor() {
            private OutputDataRate odr= OutputDataRate.ODR_125HZ;
            private AccRange ar= AccRange.AR_2G;

            @override
            public AccelerometerBma255.ConfigEditor odr(OutputDataRate odr) {
                this.odr= odr;
                return this;
            }

            @override
            public AccelerometerBma255.ConfigEditor range(AccRange ar) {
                this.ar= ar;
                return this;
            }

            @override
            public AccelerometerBma255.ConfigEditor odr(float odr) {
                float[] frequencies= OutputDataRate.frequencies();
                int pos= Util.closestIndex(frequencies, odr);

                return odr(OutputDataRate.values()[pos]);
            }

            @override
            public AccelerometerBma255.ConfigEditor range(float fsr) {
                float[] ranges= AccRange.ranges();
                int pos= Util.closestIndex(ranges, fsr);

                return range(AccRange.values()[pos]);
            }

            @override
            public void commit() {
                accDataConfig[0]&= 0xe0;
                accDataConfig[0]|= odr.ordinal() + 8;

                accDataConfig[1]&= 0xf0;
                accDataConfig[1]|= ar.bitmask;

                mwPrivate.sendCommand(ACCELEROMETER, DATA_CONFIG, accDataConfig);
            }
        };
    }

    @override
    double getOdr() {
        return OutputDataRate.values()[(accDataConfig[0] & ~0xe0) - 8].frequency;
    }

    @override
    double getRange() {
        return AccRange.bitMaskToRange((byte) (accDataConfig[1] & ~0xf0)).range;
    }

    @override
    Future<void> pullConfigAsync() {
        return pullConfigTask.execute("Did not receive BMA255 acc config within %dms", Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, Util.setRead(DATA_CONFIG)})
        ).onSuccessTask(task -> {
            System.arraycopy(task.getResult(), 2, accDataConfig, 0, accDataConfig.length);
            return Task.forResult(null);
        });
    }


    @override
    public AccelerometerBma255.FlatDataProducer flat() {
        if (flat == null) {
            flat = new Bma255FlatDataProducer();
        }
        return (AccelerometerBma255.FlatDataProducer) flat;
    }

    @override
    public LowHighDataProducer lowHigh() {
        if (lowhigh == null) {
            lowhigh = new LowHighDataProducerInner(new byte[] {0x09, 0x30, (byte) 0x81, 0x0f, (byte) 0xc0}, 2.0f);
        }
        return (LowHighDataProducer) lowhigh;
    }

    @override
    T motion<T extends MotionDetection>() {
        if (motionClass.equals(NoMotionDataProducer.class)) {
            return motionClass.cast(noMotion());
        }
        if (motionClass.equals(AnyMotionDataProducer.class)) {
            return motionClass.cast(anyMotion());
        }
        if (motionClass.equals(SlowMotionDataProducer.class)) {
            return motionClass.cast(slowMotion());
        }
        return null;
    }

    private NoMotionDataProducer noMotion() {
        if (noMotion == null) {
            noMotion = new NoMotionDataProducer() {
                @override
                public void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0x78, (byte) 0});
                }

                @override
                public void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0, (byte) 0x78});
                }

                @override
                public NoMotionConfigEditor configure() {
                    return new NoMotionConfigEditor() {
                        private Integer duration= null;
                        private Float threshold= null;

                        @override
                        public NoMotionConfigEditor duration(int duration) {
                            this.duration= duration;
                            return this;
                        }

                        @override
                        public NoMotionConfigEditor threshold(float threshold) {
                            this.threshold= threshold;
                            return this;
                        }

                        @override
                        public void commit() {
                            byte[] motionConfig = Arrays.copyOf(DEFAULT_MOTION_CONFIG, DEFAULT_MOTION_CONFIG.length);
                            if (duration != null) {
                                motionConfig[0]&= 0x3;

                                if (duration >= 1000 && duration <= 16000) {
                                    motionConfig[0]|= (byte) (((duration - 1000) / 1000) << 2);
                                } else if (duration >= 20000 && duration <= 80000) {
                                    motionConfig[0]|= (((byte) (duration - 20000) / 4000) << 2) | 0x40;
                                } else if (duration >= 88000 && duration <= 336000) {
                                    motionConfig[0]|= (((byte) (duration - 88000) / 8000) << 2) | 0x80;
                                }
                            }

                            if (threshold != null) {
                                motionConfig[2]= (byte) (threshold / BOSCH_NO_MOTION_THS_STEPS[getSelectedAccRange()]);
                            }

                            mwPrivate.sendCommand(ACCELEROMETER, MOTION_CONFIG, motionConfig);
                        }
                    };
                }

                @override
                public Task<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, MOTION_PRODUCER);
                }

                @override
                public String name() {
                    return MOTION_PRODUCER;
                }
            };
        }
        return (NoMotionDataProducer) noMotion;
    }
    AnyMotionDataProducer anyMotion() {
        if (anyMotion == null) {
            anyMotion = new AnyMotionDataProducer() {
                @override
                public void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0x7, (byte) 0});
                }

                @override
                public void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0x0, (byte) 7});
                }

                @override
                public AnyMotionConfigEditor configure() {
                    return new AnyMotionConfigEditorInner(Arrays.copyOf(DEFAULT_MOTION_CONFIG, DEFAULT_MOTION_CONFIG.length));
                }

                @override
                public Task<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, MOTION_PRODUCER);
                }

                @override
                public String name() {
                    return MOTION_PRODUCER;
                }
            };
        }
        return (AnyMotionDataProducer) anyMotion;
    }
    SlowMotionDataProducer slowMotion() {
        if (slowMotion == null) {
            slowMotion = new SlowMotionDataProducer() {
                @override
                public void start() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0x38, (byte) 0});
                }

                @override
                public void stop() {
                    mwPrivate.sendCommand(new byte[] {ACCELEROMETER.id, MOTION_INTERRUPT_ENABLE, (byte) 0x00, (byte) 0x38});
                }

                @override
                public SlowMotionConfigEditor configure() {
                    return new SlowMotionConfigEditorInner(Arrays.copyOf(DEFAULT_MOTION_CONFIG, DEFAULT_MOTION_CONFIG.length));
                }

                @override
                public Task<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, MOTION_PRODUCER);
                }

                @override
                public String name() {
                    return MOTION_PRODUCER;
                }
            };
        }
        return (SlowMotionDataProducer) slowMotion;
    }
}
