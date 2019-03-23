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
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/ProximityTsl2671.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'dart:typed_data';

class _ConfigEditor extends ConfigEditor {
    ReceiverDiode diode = ReceiverDiode.CHANNEL_1;
    TransmitterDriveCurrent driveCurrent = TransmitterDriveCurrent.CURRENT_25MA;
    int nPulses = 1;
    int pTime = 0xff;
    final MetaWearBoardPrivate _metaWearBoardPrivate;

    _ConfigEditor(this._metaWearBoardPrivate);

    @override
    ConfigEditor integrationTime(double time) {
        pTime = (256.0 - time / 2.72).floor();
        return this;
    }

    @override
    ConfigEditor pulseCount(int nPulses) {
        this.nPulses = nPulses;
        return this;
    }

    @override
    ConfigEditor receiverDiode(ReceiverDiode diode) {
        this.diode = diode;
        return this;
    }

    @override
    ConfigEditor transmitterDriveCurrent(TransmitterDriveCurrent current) {
        this.driveCurrent = current;
        return this;
    }

    @override
    void commit() {
        Uint8List config = Uint8List.fromList([
            pTime,
            nPulses,
            (((diode.index + 1) << 4) | (driveCurrent.index << 6))
        ]);
        _metaWearBoardPrivate.sendCommandForModule(
            ModuleType.PROXIMITY, ProximityTsl2671Impl.MODE, config);
    }
}

class _ForcedDataProducer extends ForcedDataProducer{
    final MetaWearBoardPrivate _metaWearBoardPrivate;

  _ForcedDataProducer(this._metaWearBoardPrivate);

    @override
    void read() {
        _metaWearBoardPrivate.lookupProducer(ProximityTsl2671Impl.PRODUCER).read(_metaWearBoardPrivate);
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder){
        return _metaWearBoardPrivate.queueRouteBuilder(builder, ProximityTsl2671Impl.PRODUCER);
    }

    @override
    String name() {
        return ProximityTsl2671Impl.PRODUCER;
    }
}
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

    static const String PRODUCER = "com.mbientlab.metawear.impl.ProximityTsl2671Impl.PRODUCER";
    static const int ADC = 1,
        MODE = 2;

    ForcedDataProducer proximityProducer;

    ProximityTsl2671Impl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate) {
        mwPrivate.tagProducer(PRODUCER, new UintData(
            ModuleType.PROXIMITY, Util.setSilentRead(ADC),
            new DataAttributes(Uint8List.fromList([2]), 1, 0, false)));
    }

    @override
    ConfigEditor configure() {
        return _ConfigEditor(mwPrivate);
    }

    @override
    ForcedDataProducer adc() {
        if (proximityProducer == null) {
            proximityProducer = _ForcedDataProducer(mwPrivate);
        }
        return proximityProducer;
    }
}
