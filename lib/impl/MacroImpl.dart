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

import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/module/Macro.dart';

/**
 * Created by etsai on 11/30/16.
 */
class MacroImpl extends ModuleImplBase implements Macro {
    static const int WRITE_MACRO_DELAY = 2000;
    static const int ENABLE = 0x1,
            BEGIN = 0x2, ADD_COMMAND = 0x3, END = 0x4,
            EXECUTE = 0x5, NOTIFY_ENABLE = 0x6, NOTIFY = 0x7,
            ERASE_ALL = 0x8,
            ADD_PARTIAL = 0x9;

    bool isRecording= false;
    Queue<Uint8List> commands;
    bool execOnBoot;
    TimedTask<Byte> startMacroTask;

    MacroImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate);


    @override
    void init() {
        startMacroTask = new TimedTask<>();
        this.mwPrivate.addResponseHandler(new Pair<>(MACRO.id, BEGIN), response -> startMacroTask.setResult(response[2]));
    }

    @override
    void startRecord() {
        startRecord(true);
    }

    @override
    void startRecord(bool execOnBoot) {
        isRecording = true;
        commands = new LinkedList<>();
        this.execOnBoot = execOnBoot;
    }

    @override
    Task<Byte> endRecordAsync() {
        isRecording = false;
        return Task.delay(WRITE_MACRO_DELAY).onSuccessTask(ignored ->
                startMacroTask.execute("Did not received macro id within %dms", Constant.RESPONSE_TIMEOUT,
                        () -> mwPrivate.sendCommand(new byte[] {MACRO.id, BEGIN, (byte) (this.execOnBoot ? 1 : 0)})
                )
        ).onSuccessTask(task -> {
            while(!commands.isEmpty()) {
                for(byte[] converted: convertToMacroCommand(commands.poll())) {
                    mwPrivate.sendCommand(converted);
                }
            }
            mwPrivate.sendCommand(new byte[] {MACRO.id, END});

            return task;
        });
    }

    @override
    void execute(byte id) {
        mwPrivate.sendCommand(new byte[] {MACRO.id, EXECUTE, id});
    }

    @override
    void eraseAll() {
        mwPrivate.sendCommand(new byte[] {MACRO.id, ERASE_ALL});
    }

    void collectCommand(byte[] command) {
        commands.add(command);
    }

    bool isRecording() {
        return isRecording;
    }

    List<Uint8List> convertToMacroCommand(Uint8List command) {
        if (command.length >= Constant.COMMAND_LENGTH) {
            byte[][] macroCmds = new byte[2][];

            final byte PARTIAL_LENGTH= 2;
            macroCmds[0]= new byte[PARTIAL_LENGTH + 2];
            macroCmds[0][0]= MACRO.id;
            macroCmds[0][1]= ADD_PARTIAL;
            System.arraycopy(command, 0, macroCmds[0], 2, PARTIAL_LENGTH);

            macroCmds[1]= new byte[command.length - PARTIAL_LENGTH + 2];
            macroCmds[1][0]= MACRO.id;
            macroCmds[1][1]= ADD_COMMAND;
            System.arraycopy(command, PARTIAL_LENGTH, macroCmds[1], 2, macroCmds[1].length - 2);

            return macroCmds;
        } else {
            byte[][] macroCmds = new byte[1][];
            macroCmds[0]= new byte[command.length + 2];
            macroCmds[0][0]= MACRO.id;
            macroCmds[0][1]= ADD_COMMAND;
            System.arraycopy(command, 0, macroCmds[0], 2, command.length);

            return macroCmds;
        }
    }
}
