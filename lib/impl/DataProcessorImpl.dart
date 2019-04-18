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
import 'dart:typed_data';

import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/impl/Version.dart';
import 'dart:collection';

import 'package:flutter_metawear/module/DataProcessor.dart';
import 'package:sprintf/sprintf.dart';
import 'package:tuple/tuple.dart';

class Processor {

    final DataTypeBase state;
    final EditorImplBase editor;

    Processor(this.state, this.editor);
}

class _ForcedDataProducer extends ForcedDataProducer {
    final MetaWearBoardPrivate mwPrivate;

    _ForcedDataProducer(this.mwPrivate);

    @override
    Future<Route> addRouteAsync(RouteBuilder builder) {
        return mwPrivate.queueRouteBuilder(builder, name());
    }

    @override
    String name() {
        return sprintf(
            "%s_state", name); //String.format(Locale.US, "%s_state", name);
    }

    @override
    void read() {
        mwPrivate.lookupProducer(name()).read(mwPrivate);
    }
}

abstract class EditorImplBase implements Editor {
    Uint8List config;
    final DataTypeBase source;

    DataProcessorConfig configObj;
    MetaWearBoardPrivate mwPrivate;

    EditorImplBase(this.configObj, this.source, this.mwPrivate): config = configObj.build();

    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        this.mwPrivate = mwPrivate;
        configObj = DataProcessorConfig.from(mwPrivate.getFirmwareVersion(), mwPrivate.lookupModuleInfo(ModuleType.DATA_PROCESSOR).revision, config);
    }
}
class NullEditor extends EditorImplBase {
    NullEditor(DataProcessorConfig configObj, DataTypeBase source,
        MetaWearBoardPrivate mwPrivate) : super(configObj, source, mwPrivate);
}

class ProcessorEntry {
    int id, offset, length;
    Uint8List source;
    Uint8List config;
}


/**
 * Created by etsai on 9/5/16.
 */
class DataProcessorImpl extends ModuleImplBase implements DataProcessor {
    static String createUri(DataTypeBase dataType,
        DataProcessorImpl dataprocessor, Version firmware, int revision) {
        int register = Util.clearRead(dataType.eventConfig[1]);
        switch (register) {
            case NOTIFY:
            case STATE:
                Processor processor = dataprocessor.lookupProcessor(
                    dataType.eventConfig[2]);
                DataProcessorConfig config = DataProcessorConfig.from(
                    firmware, revision, processor.editor.config);

                return config.createUri(
                    register == STATE, dataType.eventConfig[2]);
            default:
                return null;
        }
    }

    static const int TIME_PASSTHROUGH_REVISION = 1,
        ENHANCED_STREAMING_REVISION = 2,
        HPF_REVISION = 2,
        EXPANDED_DELAY = 2,
        FUSE_REVISION = 3;
    static const int TYPE_ACCOUNTER = 0x11,
        TYPE_PACKER = 0x10;

    static const int ADD = 2,
        NOTIFY = 3,
        STATE = 4,
        PARAMETER = 5,
        REMOVE = 6,
        NOTIFY_ENABLE = 7,
        REMOVE_ALL = 8;

    final Map<int, Processor> activeProcessors = Map();
    final Map<String, int> nameToIdMapping = Map();

    StreamController<Uint8List> _pullProcessConfigStreamController;
    StreamController<Uint8List> _createProcessorStreamController;


    DataProcessorImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);

    @override
    void restoreTransientVars(MetaWearBoardPrivate mwPrivate) {
        super.restoreTransientVars(mwPrivate);

        for (Processor it in activeProcessors.values) {
            it.editor.restoreTransientVars(mwPrivate);
        }
    }

    void init() {
        this.mwPrivate.addResponseHandler(
            Tuple2(ModuleType.DATA_PROCESSOR.id, Util.setRead(ADD)), (
            response) => _pullProcessConfigStreamController.add(response));
        this.mwPrivate.addResponseHandler(
            Tuple2(ModuleType.DATA_PROCESSOR.id, ADD), (response) =>
            _createProcessorStreamController.add(response));
    }

    void removeProcessor(bool sync, int id) {
        if (sync) {
            Processor target = activeProcessors[id];
            mwPrivate.sendCommand(Uint8List.fromList([
                ModuleType.DATA_PROCESSOR.id,
                DataProcessorImpl.REMOVE,
                target.editor.source.eventConfig[2]
            ]));
        }

        activeProcessors.remove(id);
    }

    void tearDown() {
        activeProcessors.clear();
        nameToIdMapping.clear();
        mwPrivate.sendCommand(
            Uint8List.fromList([ModuleType.DATA_PROCESSOR.id, REMOVE_ALL]));
    }

    Future<Queue<int>> queueDataProcessors(
        Queue<Processor> pendingProcessors) async {
        Queue<int> ids = Queue();

        Stream<Uint8List> stream = _createProcessorStreamController.stream
            .timeout(ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);

        try {
            while (pendingProcessors.isNotEmpty) {
                Processor current = pendingProcessors.removeLast();
                DataTypeBase input = current.editor.source.input;

                if (current.editor.configObj is Fuser) {
                    (current.editor.configObj as Fuser).syncFilterIds(this);
                }
                Uint8List filterConfig = Uint8List(
                    input.eventConfig.length + 1 +
                        current.editor.config.length);
                filterConfig[input.eventConfig.length] =
                (((input.attributes.length() - 1) << 5) | input.attributes
                    .offset);
                filterConfig.setAll(0, input.eventConfig);
                filterConfig.setAll(
                    input.eventConfig.length + 1, current.editor.config);

                TimeoutException exception = TimeoutException(
                    "Did not receive data processor id",
                    ModuleType.RESPONSE_TIMEOUT);
                mwPrivate.sendCommandForModule(
                    ModuleType.DATA_PROCESSOR, ADD, filterConfig);
                if (await iterator.moveNext().catchError((e) => throw exception,
                    test: (e) => e is TimeoutException) == false) {
                    throw exception;
                }

                int id = iterator.current[2];
                current.editor.source.eventConfig[2] = id;
                if (current.state != null) {
                    current.state.eventConfig[2] = id;
                }
                activeProcessors[id] = current;
                ids.add(id);
            }
        } catch (e) {
            await iterator.cancel();
            for (int id in ids) {
                removeProcessor(true, id);
            }
            throw e;
        }
        await iterator.cancel();
        return ids;
    }

    @override
    T edit<T extends Editor>(String name) {
        return activeProcessors[nameToIdMapping[name]].editor as T;
    }

    @override
    ForcedDataProducer state(final String name) {
        try {
            DataTypeBase state = activeProcessors[nameToIdMapping[name]].state;

            if (state != null) {
                ForcedDataProducer stateProducer = _ForcedDataProducer(
                    mwPrivate);
                mwPrivate.tagProducer(stateProducer.name(), state);
                return stateProducer;
            }
            return null;
        } on NullThrownError {
            return null;
        }
    }

    void assignNameToId(Map<String, Processor> taggedProcessors) {
        taggedProcessors.forEach((String key, Processor value) =>
        {
        nameToIdMapping[key] = value.editor.source.eventConfig[2]
        });
    }

    Processor lookupProcessor(int id) {
        return activeProcessors[id];
    }

    void addProcessor(int id, DataTypeBase state, DataTypeBase source,
        DataProcessorConfig config) {
        activeProcessors[id] =
            Processor(state, new NullEditor(config, source, mwPrivate));
    }

    Future<Queue<ProcessorEntry>> pullChainAsync(int id) async {
        bool terminate = false;
        Queue<ProcessorEntry> result = Queue();
        int nextId = id;


        TimeoutException exception = TimeoutException(
            "Did not received data processor config",
            ModuleType.RESPONSE_TIMEOUT);
        Stream<Uint8List> stream = _createProcessorStreamController.stream
            .timeout(ModuleType.RESPONSE_TIMEOUT);
        StreamIterator<Uint8List> iterator = StreamIterator(stream);

        while (terminate) {
            mwPrivate.sendCommand(Uint8List.fromList(
                [ModuleType.DATA_PROCESSOR.id, Util.setRead(ADD), nextId]));
            if (await iterator.moveNext().catchError((e) => throw exception,
                test: (e) => e is TimeoutException) == false) {
                throw exception;
            }
            Uint8List response = iterator.current;

            ProcessorEntry entry = new ProcessorEntry();
            entry.id = nextId;
            entry.offset = (response[5] & 0x1f);
            entry.length = (((response[5] >> 5) & 0x7) + 1);

            entry.source = Uint8List(3);
            entry.source.setAll(0, response.skip(2));

            entry.config = Uint8List(response.length - 6);
            entry.config.setAll(0, response.skip(6));

            result.addLast(entry);

            nextId = response[4];
            terminate = !(response[2] == ModuleType.DATA_PROCESSOR.id &&
                response[3] == NOTIFY);
        }
        return result;
    }
}
