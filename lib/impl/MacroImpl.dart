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
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/module/Macro.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:tuple/tuple.dart';

/**
 * Created by etsai on 11/30/16.
 */
class MacroImpl extends ModuleImplBase implements Macro {
    static const Duration WRITE_MACRO_DELAY = Duration(seconds: 2);
    static const int ENABLE = 0x1,
            BEGIN = 0x2, ADD_COMMAND = 0x3, END = 0x4,
            EXECUTE = 0x5, NOTIFY_ENABLE = 0x6, NOTIFY = 0x7,
            ERASE_ALL = 0x8,
            ADD_PARTIAL = 0x9;

    bool _isRecording= false;
    Queue<Uint8List> commands;
    bool execOnBoot;
    StreamController<int> _streamController;


    MacroImpl(MetaWearBoardPrivate mwPrivate): super(mwPrivate);


    @override
    void init() {
        this.mwPrivate.addResponseHandler(Tuple2(ModuleType.MACRO.id, BEGIN), (Uint8List response) => _streamController.add(response[2]));
    }

    @override
    void startRecord([bool execOnBoot = true]) {
        _isRecording = true;
        commands = Queue();
        this.execOnBoot = execOnBoot;
    }

    @override
    Future<int> endRecordAsync() async {
        _isRecording = false;
        Stream<int> stream = _streamController.stream.timeout(
            ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<int> iterator = StreamIterator(stream);


        TimeoutException exception = TimeoutException(
            "Did not received macro id", MacroImpl.WRITE_MACRO_DELAY);
        mwPrivate.sendCommand(Uint8List.fromList(
            [ModuleType.MACRO.id, BEGIN, (this.execOnBoot ? 1 : 0)]));
        if (await iterator.moveNext().catchError((e) => throw exception,
            test: (e) => e is TimeoutException) == false)
            throw exception;

        while (commands.isNotEmpty) {
            for (Uint8List converted in convertToMacroCommand(
                commands.removeLast())) {
                mwPrivate.sendCommand(converted);
            }
        }
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.MACRO.id, END]));
        int result = iterator.current;
        await iterator.cancel();
        return result;
    }

    @override
    void execute(int id) {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.MACRO.id, EXECUTE, id]));
    }

    @override
    void eraseAll() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.MACRO.id, ERASE_ALL]));
    }

    void collectCommand(Uint8List command) {
        commands.add(command);
    }

    bool isRecording() {
        return _isRecording;
    }

    List<Uint8List> convertToMacroCommand(Uint8List command) {
        if (command.length >= ModuleType.COMMAND_LENGTH) {
            List<Uint8List> macroCmds = List(2);

            final int PARTIAL_LENGTH= 2;
            macroCmds[0] = Uint8List(PARTIAL_LENGTH + 2);
            macroCmds[0][0] = ModuleType.MACRO.id;
            macroCmds[0][1] = ADD_PARTIAL;
            macroCmds[0].setAll(2,command);


            macroCmds[1] = Uint8List(command.length - PARTIAL_LENGTH + 2);
            macroCmds[1][0] = ModuleType.MACRO.id;
            macroCmds[1][1] = ADD_COMMAND;
            macroCmds[1].setAll(2,command.skip(PARTIAL_LENGTH));

            return macroCmds;
        } else {
            List<Uint8List> macroCmds = List(1);
            macroCmds[0]= Uint8List(command.length + 2);
            macroCmds[0][0]= ModuleType.MACRO.id;
            macroCmds[0][1]= ADD_COMMAND;
            macroCmds[0].setAll(2, command);
            return macroCmds;
        }
    }
}
