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

import 'package:flutter_metawear/CodeBlock.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/module/Timer.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'dart:typed_data';
import 'EventImpl.dart';
import 'package:tuple/tuple.dart';
import 'UintData.dart';

class ScheduledTaskInner implements ScheduledTask{
    final int _id;
    bool active;
    final List<int> eventCmdIds;

    MetaWearBoardPrivate mwPrivate;

    ScheduledTaskInner(this._id,this.eventCmdIds, this.mwPrivate) {
        restoreTransientVars(mwPrivate);
    }

    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate= mwPrivate;
    }

    @override
    void start() {
        if (active) {
            mwPrivate.sendCommand(Uint8List.fromList([ModuleType.TIMER.id, TimerImpl.START, _id]));
        }
    }

    @override
    void stop() {
        if (active) {
            mwPrivate.sendCommand(Uint8List.fromList([ModuleType.TIMER.id, TimerImpl.STOP, _id]));
        }
    }


    @override
    void remove([bool sync]) {
        if (active) {
            active = false;

            if (sync || sync == null) {
                mwPrivate.sendCommand(new Uint8List.fromList(
                    [ModuleType.TIMER.id, TimerImpl.REMOVE, _id]));
                (mwPrivate.getModules()[TimerModule] as TimerImpl).activeTasks
                    .remove(id);

                EventImpl event = mwPrivate.getModules()[EventImpl];
                for (int it in eventCmdIds) {
                    event.removeEventCommand(it);
                }
            }
        }
    }

    @override
    int id() {
        return _id;
    }

    @override
    bool isActive() {
        return active;
    }
}

/**
 * Created by etsai on 9/17/16.
 */
class TimerImpl extends ModuleImplBase implements TimerModule {

    static const int TIMER_ENTRY = 2,
        START = 3,
        STOP = 4,
        REMOVE = 5,
        NOTIFY = 6,
        NOTIFY_ENABLE = 7;


    final Map<int, ScheduledTask> activeTasks = Map();
    final StreamController<int> _streamController = StreamController<int>();


    TimerImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);

    @override
    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for (ScheduledTask it in activeTasks.values) {
            (it as ScheduledTaskInner).restoreTransientVars(mwPrivate);
        }
    }

    @override
    void init() {
        this.mwPrivate.addResponseHandler(
            Tuple2(ModuleType.TIMER.id, TIMER_ENTRY), (Uint8List response) =>
            _streamController.add(response[2]));
    }

    @override
    void tearDown() {
        for (ScheduledTask it in activeTasks.values) {
            (it as ScheduledTaskInner).remove(false);
        }
        activeTasks.clear();

        for (int i = 0; i < mwPrivate
            .lookupModuleInfo(ModuleType.TIMER)
            .extra[0]; i++) {
            mwPrivate.sendCommand(
                Uint8List.fromList([ModuleType.TIMER.id, REMOVE, i]));
        }
    }

    Future<DataTypeBase> create(Uint8List config) async {
        Stream<int> stream = _streamController.stream.timeout(
            ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<int> iterator = StreamIterator(stream);

        TimeoutException exception = TimeoutException(
            "Did not received timer id", ModuleType.RESPONSE_TIMEOUT);
        mwPrivate.sendCommandForModule(ModuleType.TIMER, TIMER_ENTRY, config);
        if (await iterator.moveNext().catchError((e) => throw exception,
            test: (e) => e is TimeoutException) == false)
            throw exception;
        int id = iterator.current;
        await iterator.cancel();

        return UintData(ModuleType.TIMER, TimerImpl.NOTIFY,
            DataAttributes(Uint8List(0), 0, 0, false), id: id);
    }

    @override
    Future<ScheduledTask> scheduleAsync(int period, bool delay,
        CodeBlock mwCode) {
        return scheduleAsyncRepeated(period, -1, delay, mwCode);
    }

    @override
    Future<ScheduledTask> scheduleAsyncRepeated(int period, int repetitions,
        bool delay, CodeBlock mwCode) {
        Uint8List payload = Uint8List(7);
        ByteData data = ByteData.view(payload.buffer);
        data.setInt8(0, period);
        data.setInt16(1, repetitions);
        data.setInt8(3, delay ? 0 : 1);
        return mwPrivate.queueTaskManager(mwCode, payload);
    }

    @override
    ScheduledTask lookupScheduledTask(int id) {
        return activeTasks[id];
    }

    ScheduledTask createTimedEventManager(int id, List<int> eventCmdIds) {
        ScheduledTaskInner newTask = new ScheduledTaskInner(
            id, eventCmdIds, mwPrivate);
        activeTasks[id] = newTask;
        return newTask;
    }
}
