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

import 'package:flutter_metawear/CodeBlock.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';


import 'package:tuple/tuple.dart';
import 'dart:typed_data';
/**
 * Created by etsai on 10/26/16.
 */
class EventImpl extends ModuleImplBase implements Module {
    static const int ENTRY = 2, CMD_PARAMETERS = 3, REMOVE = 4, REMOVE_ALL = 5;

    Tuple3<int, int, int> feedbackParams= null;
    DataTypeBase activeDataType = null;
    Queue<Uint8List> recordedCommands;
    final StreamController<Uint8List> _streamController = StreamController<Uint8List>();

    EventImpl(MetaWearBoardPrivate mwPrivate):super(mwPrivate);

    void init() {
        mwPrivate.addResponseHandler(Tuple2(ModuleType.EVENT.id, ENTRY), (Uint8List response)=> _streamController.add(response));
    }

    @override
    void tearDown() {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.EVENT.id, EventImpl.REMOVE_ALL]));
    }

    void removeEventCommand(int id) {
        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.EVENT.id, EventImpl.REMOVE, id]));
    }

    Future<List<int>> queueEvents(final Queue<Tuple2<DataTypeBase,CodeBlock>> eventCodeBlocks) async {

        Stream<Uint8List> stream = _streamController.stream.timeout(ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);
        List ids = [];

        try {
            while (!eventCodeBlocks.isEmpty) {
                Tuple2<DataTypeBase, CodeBlock> entry = eventCodeBlocks
                    .removeLast();
                activeDataType = entry.item1;
                recordedCommands = Queue();
                entry.item2.program();
                activeDataType = null;
                entry.item2.program();
                TimeoutException exception;

                while (!recordedCommands.isEmpty) {
                    mwPrivate.sendCommand(recordedCommands.removeLast());
                    mwPrivate.sendCommand(recordedCommands.removeLast());
                    exception = TimeoutException("Did not receive event id",
                        ModuleType.RESPONSE_TIMEOUT);
                    if (await iterator.moveNext().catchError((
                        e) => throw exception,
                        test: (e) => e is TimeoutException) == false)
                        throw exception;
                    ids.add(iterator.current[2]);
                }
            }
        }
        catch (e){
            for(int id in ids){
                removeEventCommand(id);
            }
            throw e;
        }
        return ids;
    }

    void convertToEventCommand(Uint8List command) {
        Uint8List commandEntry= Uint8List.fromList([ModuleType.EVENT.id, EventImpl.ENTRY,
                activeDataType.eventConfig[0], activeDataType.eventConfig[1], activeDataType.eventConfig[2],
                command[0], command[1], (command.length - 2)]);

        if (feedbackParams != null) {
            Uint8List tempEntry= Uint8List(commandEntry.length + 2);
            tempEntry.setAll(0, commandEntry);
            tempEntry[commandEntry.length]= (0x01 | ((feedbackParams.item1<< 1) & 0xff) | ((feedbackParams.item2 << 4) & 0xff));
            tempEntry[commandEntry.length + 1]= feedbackParams.item3;
            commandEntry= tempEntry;
        }
        recordedCommands.add(commandEntry);

        Uint8List eventParameters= Uint8List(command.length);
        eventParameters.setAll(2, command.skip(2));
        eventParameters[0]= ModuleType.EVENT.id;
        eventParameters[1]= EventImpl.CMD_PARAMETERS;
        recordedCommands.add(eventParameters);
    }
}
