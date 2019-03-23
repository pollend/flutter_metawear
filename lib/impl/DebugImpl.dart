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

import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/module/Debug.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'ModuleType.dart';
import 'package:tuple/tuple.dart';
import 'Util.dart';
import 'dart:typed_data';

/**
 * Created by etsai on 10/11/16.
 */
class DebugImpl extends ModuleImplBase implements Debug {
    static const int POWER_SAVE_REVISION = 1;
    static const int TMP_VALUE = 0x4;

    TimedTask<byte[]> readTmpValueTask;

    DebugImpl(MetaWearBoardPrivate mwPrivate) : super(null);

    void init() {
        readTmpValueTask = new TimedTask<>();
        this.mwPrivate.addResponseHandler(Tuple2(ModuleType.DEBUG.id, Util.setRead(TMP_VALUE)), (Uint8List response )=> readTmpValueTask.setResult(response));
    }

    @override
    Future<void> resetAsync() {
        EventImpl event = (EventImpl) mwPrivate.getModules().get(EventImpl.class);
        Future<void> task= (event != null && event.activeDataType != null) ? Task.cancelled() : mwPrivate.boardDisconnect();

        mwPrivate.sendCommand(new byte[] {DEBUG.id, 0x1});
        return task;
    }

    @override
    Future<void> disconnectAsync() {
        EventImpl event = (EventImpl) mwPrivate.getModules().get(EventImpl.class);
        Future<void> task= (event != null && event.activeDataType != null) ? Task.cancelled() : mwPrivate.boardDisconnect();

        mwPrivate.sendCommand(new byte[] {DEBUG.id, 0x6});
        return task;
    }

    @override
    Future<void> jumpToBootloaderAsync() {
        EventImpl event = (EventImpl) mwPrivate.getModules()[EventImpl];
        Future<void> task= (event != null && event.activeDataType != null) ? Task.cancelled() : mwPrivate.boardDisconnect();

        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.DEBUG.id, 0x2]));
        return task;
    }

    @override
    void resetAfterGc() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.DEBUG.id, 0x5]));
    }

    @override
    void writeTmpValue(int value) {
        ByteBuffer buffer = ByteBuffer.allocate(6).order(ByteOrder.LITTLE_ENDIAN)
                .put(DEBUG.id)
                .put(TMP_VALUE)
                .putInt(value);
        mwPrivate.sendCommand(buffer.array());
    }

    @override
    Future<int> readTmpValueAsync() {
        return readTmpValueTask.execute("Did not received response from tmp register within %dms", Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(new byte[] {DEBUG.id, Util.setRead(TMP_VALUE)})
        ).onSuccessTask(task -> Task.forResult(ByteBuffer.wrap(task.getResult(), 2, 4).order(ByteOrder.LITTLE_ENDIAN).getInt()));
    }

    @override
    bool enablePowersave() {
        if (mwPrivate.lookupModuleInfo(ModuleType.DEBUG).revision >= POWER_SAVE_REVISION) {
            mwPrivate.sendCommand(new byte[] {ModuleType.DEBUG.id, 0x07});
            return true;
        }
        return false;
    }
}
