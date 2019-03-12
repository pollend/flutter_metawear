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

import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/ProximityTsl2671.dart';

/**
 * Created by etsai on 9/19/16.
 */
class ProximityTsl2671Impl extends ModuleImplBase implements ProximityTsl2671 {
    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case ADC:
                return "proximity";
            default:
                return null;
        }
    }

    static const String PRODUCER= "com.mbientlab.metawear.impl.ProximityTsl2671Impl.PRODUCER";
    static const int ADC= 1, MODE= 2;

    ForcedDataProducer proximityProducer;

    ProximityTsl2671Impl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate){
        mwPrivate.tagProducer(PRODUCER, new UintData(PROXIMITY, Util.setSilentRead(ADC), new DataAttributes(new byte[] {2}, (byte) 1, (byte) 0, false)));
    }

    @override
    public ConfigEditor configure() {
        return new ConfigEditor() {
            private ReceiverDiode diode= ReceiverDiode.CHANNEL_1;
            private TransmitterDriveCurrent driveCurrent= TransmitterDriveCurrent.CURRENT_25MA;
            private byte nPulses= 1;
            private byte pTime= (byte) 0xff;

            @override
            public ConfigEditor integrationTime(float time) {
                pTime= (byte) (256.f - time / 2.72f);
                return this;
            }

            @override
            public ConfigEditor pulseCount(byte nPulses) {
                this.nPulses= nPulses;
                return this;
            }

            @override
            public ConfigEditor receiverDiode(ReceiverDiode diode) {
                this.diode= diode;
                return this;
            }

            @override
            public ConfigEditor transmitterDriveCurrent(TransmitterDriveCurrent current) {
                this.driveCurrent= current;
                return this;
            }

            @override
            public void commit() {
                byte[] config= new byte[] {pTime, nPulses, (byte) (((diode.ordinal() + 1) << 4) | (driveCurrent.ordinal() << 6))};
                mwPrivate.sendCommand(PROXIMITY, MODE, config);
            }
        };
    }

    @override
    public ForcedDataProducer adc() {
        if (proximityProducer == null) {
            proximityProducer = new ForcedDataProducer() {
                @override
                public void read() {
                    mwPrivate.lookupProducer(PRODUCER).read(mwPrivate);
                }

                @override
                public Task<Route> addRouteAsync(RouteBuilder builder) {
                    return mwPrivate.queueRouteBuilder(builder, PRODUCER);
                }

                @override
                public String name() {
                    return PRODUCER;
                }
            };
        }
        return proximityProducer;
    }
}
