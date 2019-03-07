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


import 'package:flutter_metawear/ActiveDataProducer.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/UintData.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/impl/platform/TimedTask.dart';
import 'package:flutter_metawear/module/Switch.dart';


import 'package:tuple/tuple.dart';



class _ActiveDataProducer extends ActiveDataProducer {

    final MetaWearBoardPrivate mwPrivate;

    _ActiveDataProducer(this.mwPrivate);

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) =>
        mwPrivate.queueRouteBuilder(builder, SwitchImpl.PRODUCER);


    @override
    String name() => SwitchImpl.PRODUCER;
}

/**
 * Created by etsai on 9/4/16.
 */
class SwitchImpl extends ModuleImplBase implements Switch {
    static const String PRODUCER= "com.mbientlab.metawear.impl.SwitchImpl.PRODUCER";
    static const int STATE= 0x1;

    static String createUri(DataTypeBase dataType) {
        switch (Util.clearRead(dataType.eventConfig[1])) {
            case SwitchImpl.STATE:
                return "switch";
            default:
                return null;
        }
    }

    ActiveDataProducer _state;
    TimedTask<int> _stateTasks;

    SwitchImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate) {
        this.mwPrivate.tagProducer(PRODUCER, new UintData(ModuleType.SWITCH, STATE, new DataAttributes(new byte[] {1}, (byte) 1, (byte) 0, false)));
    }

    @override
    void init() {
        _stateTasks = TimedTask<>();
        this.mwPrivate.addResponseHandler(Tuple2<int,int>( ModuleType.SWITCH.id, Util.setRead(STATE)), response -> stateTasks.setResult(response[2]));
    }

    @override
    ActiveDataProducer state() {
        if (_state == null) {
            _state = _ActiveDataProducer(mwPrivate);
        }
        return _state;
    }

    @override
    Future<int> readCurrentStateAsync() {
        return stateTasks.execute("Did not received button state within %dms",  Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(new byte[] {SWITCH.id, Util.setRead(STATE)}));
    }
}
