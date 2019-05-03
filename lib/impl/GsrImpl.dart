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
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/module/Gsr.dart';
import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'dart:typed_data';
import 'package:sprintf/sprintf.dart';

class Channel implements ForcedDataProducer {
    final int id;
    MetaWearBoardPrivate mwPrivate;

    Channel(this.id, this.mwPrivate) {
        mwPrivate.tagProducer(name(), new UintData(
            ModuleType.GSR, Util.setSilentRead(GsrImpl.CONDUCTANCE),
            new DataAttributes(Uint8List.fromList([4]), 1, 0, false), id: id));
    }

    void restoreTransientVariables(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate = mwPrivate;
    }

    @override
    void read() {
        mwPrivate.lookupProducer(name()).read(mwPrivate);
    }

    @override
    String name() {
        return sprintf(GsrImpl.CONDUCTANCE_PRODUCER_FORMAT, id);
    }

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, name());
    }
}

class _ConfigEditor extends ConfigEditor {
    ConstantVoltage _newCv = ConstantVoltage.CV_500MV;
    Gain _newGain = Gain.GSR_499K;

    final MetaWearBoardPrivate _mwPrivate;

    _ConfigEditor(this._mwPrivate);

    @override
    void commit() {
        _mwPrivate.sendCommandForModule(ModuleType.GSR, GsrImpl.CONFIG,
            Uint8List.fromList([_newCv.index, _newGain.index]));
    }

    @override
    ConfigEditor constantVoltage(ConstantVoltage cv) {
        _newCv = cv;
        return this;
    }

    @override
    ConfigEditor gain(Gain gain) {
        _newGain = gain;
        return this;
    }
}

class GsrImpl extends ModuleImplBase implements Gsr {
    static const String CONDUCTANCE_PRODUCER_FORMAT= "com.mbientlab.metawear.impl.GsrImpl.CONDUCTANCE_PRODUCER_%d";
    static const  int CONDUCTANCE = 0x1, CALIBRATE = 0x2, CONFIG= 0x3;
    List<Channel> conductanceChannels;

    GsrImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate) {
        Uint8List extra = mwPrivate
            .lookupModuleInfo(ModuleType.GSR)
            .extra;
        conductanceChannels = List<Channel>(extra[0]);
        for (int i = 0; i < extra[0]; i++) {
            conductanceChannels[i] = new Channel(i, mwPrivate);
        }
    }

    @override
    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for(Channel it in conductanceChannels) {
            it.restoreTransientVariables(mwPrivate);
        }
    }

    @override
    ConfigEditor configure() {
        return _ConfigEditor(mwPrivate);
    }

    @override
    List<Channel> channels() {
        return conductanceChannels;
    }

    @override
    void calibrate() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.GSR.id, CALIBRATE]));
    }
}
