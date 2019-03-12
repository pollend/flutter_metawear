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

import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/DeviceDataConsumer.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/platform/TimedTask.dart';
import 'package:flutter_metawear/module/Logging.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter_metawear/impl/Util.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:tuple/tuple.dart';

class DataLogger extends DeviceDataConsumer {

    final Map<int, Queue<Uint8List>> logEntries = Map();

    DataLogger(DataTypeBase source) : super(source);

    void addId(int id) {
        logEntries[id] = Queue();
    }

    void remove(MetaWearBoardPrivate mwPrivate) {
        for (int id in logEntries.keys) {
            mwPrivate.sendCommand(
                Uint8List.fromList(
                    [ModuleType.LOGGING.id, LoggingImpl.REMOVE, id]));
        }
    }

    void register(Map<int, DataLogger> loggers) {
        for (int id in logEntries.keys) {
            loggers[id] = this;
        }
    }

    void handleLogMessage(final MetaWearBoardPrivate mwPrivate, int logId,
        final DateTime timestamp, Uint8List data,
        Function(DownloadError errorType, int logId, DateTime timestamp, Uint8List data) handler) {
        if (subscriber == null) {
            if (handler != null) {
                handler(
                    DownloadError.UNHANDLED_LOG_DATA, logId, timestamp, data);
            } else {
                mwPrivate.logWarn(sprintf(
                    "No subscriber to handle log data: {logId: %d, time: %d, data: %s}",
                    [logId, timestamp.millisecond, Util.arrayToHexString(data)
                    ]));
            }

            return;
        }

        if (logEntries.containsKey(logId)) {
            logEntries[logId].add(data);
        } else if (handler != null) {
            handler(DownloadError.UNKNOWN_LOG_ENTRY, logId, timestamp, data);
        }

        bool noneEmpty = true;
        for (Queue<Uint8List> cachedValues in logEntries.values) {
            noneEmpty &= !cachedValues.isEmpty;
        }

        if (noneEmpty) {
            List<Uint8List> entries = new List(logEntries.values.length);
            for (Queue<Uint8List> cachedValues in logEntries.values) {
                entries.add(cachedValues.removeFirst());
            }

            final Uint8List merged = Uint8List(source.attributes.length());
            int offset = 0;
            for (int i = 0; i < entries.length; i++) {
                int copyLength = min(
                    entries[i].length, source.attributes.length() - offset);
                merged.setAll(offset, entries[i]);
                //System.arraycopy(entries.get(i), 0, merged, offset, copyLength);
                offset += entries[i].length;
            }

            call(
                source.createMessage(true, mwPrivate, merged, timestamp, null));
        }
    }

    @override
    void enableStream(MetaWearBoardPrivate mwPrivate) {
    }

    @override
    void disableStream(MetaWearBoardPrivate mwPrivate) {
    }

    @override
    void addDataHandler(final MetaWearBoardPrivate mwPrivate) {
    }
}


class TimeReference {
    final int resetUid;
    int tick;
    final DateTime timestamp;

    TimeReference(this.resetUid, this.tick, this.timestamp);
}

/**
 * Created by etsai on 9/4/16.
 */
class LoggingImpl extends ModuleImplBase implements Logging {
    static const double TICK_TIME_STEP= (48.0 / 32768.0) * 1000.0;
    static const int LOG_ENTRY_SIZE= 4, REVISION_EXTENDED_LOGGING = 2;
    static const int ENABLE = 1,
            TRIGGER = 2,
            REMOVE = 3,
            TIME = 4,
            LENGTH = 5,
            READOUT = 6, READOUT_NOTIFY = 7, READOUT_PROGRESS = 8,
            REMOVE_ENTRIES = 9, REMOVE_ALL = 0xa,
            CIRCULAR_BUFFER = 0xb,
            READOUT_PAGE_COMPLETED = 0xd, READOUT_PAGE_CONFIRM = 0xe;

    // Logger state
    final Map<int, TimeReference> logReferenceTicks= Map();
    final HashMap<Byte, Long> lastTimestamp = Map();
    TimeReference latestReference;
    final HashMap<Byte, DataLogger> dataLoggers= Map();
    HashMap<int, int> rollbackTimestamps = Map();

    int nLogEntries;
    int nUpdates;
    LogDownloadUpdateHandler updateHandler;
    LogDownloadErrorHandler errorHandler;

    AtomicReference<TaskCompletionSource<Void>> downloadTask;
    TimedTask<Uint8List> createLoggerTask, syncLoggerConfigTask;
    TimedTask<void> queryTimeTask;

    LoggingImpl(MetaWearBoardPrivate mwPrivate) {
        super(mwPrivate);
    }

    @override
    void disconnected() {
        rollbackTimestamps.putAll(lastTimestamp);
        TaskCompletionSource<Void> taskSource = downloadTask.getAndSet(null);
        if (taskSource != null) {
            taskSource.setError(new RuntimeException("Lost connection while downloading log data"));
        }
    }

    void removeDataLogger(bool sync, DataLogger logger) {
        if (sync) {
            logger.remove(mwPrivate);
        }

        for (int id in logger.logEntries.keys) {
            dataLoggers.remove(id);
        }
    }

    void completeDownloadTask() {
        rollbackTimestamps.clear();
        TaskCompletionSource<Void> taskSource = downloadTask.getAndSet(null);
        if (taskSource != null) {
            taskSource.setResult(null);
        } else {
            mwPrivate.logWarn("Log download finished but no Task object to complete");
        }
    }

    @override
    void tearDown() {
        dataLoggers.clear();

        mwPrivate.sendCommand(Uint8List.fromList([ModuleType.LOGGING.id, REMOVE_ALL]));
    }

    Map<Tuple3<int, int, int>, int> placeholder;
    DataTypeBase guessLogSource(Iterable<DataTypeBase> producers, Tuple3<int, int, int> key, int offset, int length) {
        List<DataTypeBase> possible = [];

        for(DataTypeBase it in producers) {
            if (it.eventConfig[0] == key.item1 && it.eventConfig[1] == key.item2 && it.eventConfig[2] == key.item3) {
                possible.add(it);
            }
        }

        DataTypeBase original = null;
        bool multipleEntries = false;
        for(DataTypeBase it: possible) {
            if (it.attributes.length() > 4) {
                original = it;
                multipleEntries = true;
            }
        }

        if (multipleEntries) {
            if (offset == 0 && length > LOG_ENTRY_SIZE) {
                return original;
            }
            if (!placeholder.containsKey(key) && length == LOG_ENTRY_SIZE) {
                placeholder[key] = length;
                return original;
            }
            if (placeholder.containsKey(key)) {
                byte newLength = (byte) (placeholder.get(key) + length);
                if (newLength == original.attributes.length()) {
                    placeholder.remove(key);
                }
                return original;
            }
        }

        for(DataTypeBase it: possible) {
            if (it.attributes.offset == offset && it.attributes.length() == length) {
                return it;
            }
        }
        return null;
    }

    @override
    void init() {
        createLoggerTask = new TimedTask<>();
        syncLoggerConfigTask = new TimedTask<>();

        downloadTask = new AtomicReference<>();
        if (rollbackTimestamps == null) {
            rollbackTimestamps = new HashMap<>();
        }

        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, Util.setRead(TRIGGER)), response -> syncLoggerConfigTask.setResult(response));
        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, TRIGGER), response -> createLoggerTask.setResult(response));
        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, READOUT_NOTIFY), response -> {
            processLogData(Arrays.copyOfRange(response, 2, 11));

            if (response.length == 20) {
                processLogData(Arrays.copyOfRange(response, 11, 20));
            }
        });
        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, READOUT_PROGRESS), response -> {
            byte[] padded= new byte[8];
            System.arraycopy(response, 2, padded, 0, response.length - 2);
            long nEntriesLeft= ByteBuffer.wrap(padded).order(ByteOrder.LITTLE_ENDIAN).getLong(0);

            if (nEntriesLeft == 0) {
                completeDownloadTask();
            } else if (updateHandler != null) {
                updateHandler.receivedUpdate(nEntriesLeft, nLogEntries);
            }
        });
        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, Util.setRead(TIME)), response -> {
            byte[] padded= new byte[8];
            System.arraycopy(response, 2, padded, 0, 4);
            final long tick= ByteBuffer.wrap(padded).order(ByteOrder.LITTLE_ENDIAN).getLong(0);
            byte resetUid= (response.length > 6) ? response[6] : -1;

            // if in the middle of a log download, don't update the reference
            // rollbackTimestamps var is cleared after readout progress hits 0
            if (rollbackTimestamps.isEmpty()) {
                latestReference = new TimeReference(resetUid, tick, Calendar.getInstance());
                if (resetUid != -1) {
                    logReferenceTicks.put(latestReference.resetUid, latestReference);
                }
            }

            if (queryTimeTask != null) {
                queryTimeTask.setResult(null);
                queryTimeTask = null;
            }
        });
        this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, Util.setRead(LENGTH)), response -> {
            int payloadSize= response.length - 2;

            byte[] padded= new byte[8];
            System.arraycopy(response, 2, padded, 0, payloadSize);
            nLogEntries= ByteBuffer.wrap(padded).order(ByteOrder.LITTLE_ENDIAN).getLong();

            if (nLogEntries == 0) {
                completeDownloadTask();
            } else {
                if (updateHandler != null) {
                    updateHandler.receivedUpdate(nLogEntries, nLogEntries);
                }

                long nEntriesNotify = nUpdates == 0 ? 0 : (long) (nLogEntries * (1.0 / nUpdates));

                ///< In little endian, [A, B, 0, 0] is equal to [A, B]
                ByteBuffer readoutCommand = ByteBuffer.allocate(payloadSize + 4).order(ByteOrder.LITTLE_ENDIAN)
                        .put(response, 2, payloadSize).putInt((int) nEntriesNotify);
                mwPrivate.sendCommand(LOGGING, READOUT, readoutCommand.array());
            }
        });

        if (mwPrivate.lookupModuleInfo(LOGGING).revision >= REVISION_EXTENDED_LOGGING) {
            this.mwPrivate.addResponseHandler(new Pair<>(LOGGING.id, READOUT_PAGE_COMPLETED), response -> mwPrivate.sendCommand(new byte[] {LOGGING.id, READOUT_PAGE_CONFIRM}));
        }
    }

    @override
    void start(boolean overwrite) {
        mwPrivate.sendCommand(new byte[] {LOGGING.id, CIRCULAR_BUFFER, (byte) (overwrite ? 1 : 0)});
        mwPrivate.sendCommand(new byte[] {LOGGING.id, ENABLE, 1});
    }

    @override
    void stop() {
        mwPrivate.sendCommand(new byte[] {LOGGING.id, ENABLE, 0});
    }

    @override
    Future<void> downloadAsync(int nUpdates, LogDownloadUpdateHandler updateHandler, LogDownloadErrorHandler errorHandler) {
        TaskCompletionSource<Void> taskSource = downloadTask.get();
        if (taskSource != null) {
            return taskSource.getTask();
        }

        this.nUpdates = nUpdates;
        this.updateHandler= updateHandler;
        this.errorHandler= errorHandler;

        if (mwPrivate.lookupModuleInfo(LOGGING).revision >= REVISION_EXTENDED_LOGGING) {
            mwPrivate.sendCommand(new byte[] {LOGGING.id, READOUT_PAGE_COMPLETED, 1});
        }
        mwPrivate.sendCommand(new byte[] {LOGGING.id, READOUT_NOTIFY, 1});
        mwPrivate.sendCommand(new byte[] {LOGGING.id, READOUT_PROGRESS, 1});
        mwPrivate.sendCommand(new byte[] {LOGGING.id, Util.setRead(LENGTH)});

        taskSource = new TaskCompletionSource<>();
        downloadTask.set(taskSource);
        return taskSource.getTask();
    }

    @override
    Future<void> downloadAsync(int nUpdates, LogDownloadUpdateHandler updateHandler) {
        return downloadAsync(nUpdates, updateHandler, null);
    }

    @override
    Future<void> downloadAsync(LogDownloadErrorHandler errorHandler) {
        return downloadAsync(0, null, errorHandler);
    }

    @override
    Future<void> downloadAsync() {
        return downloadAsync(0, null, null);
    }

    @override
    void clearEntries() {
        if (mwPrivate.lookupModuleInfo(LOGGING).revision >= REVISION_EXTENDED_LOGGING) {
            mwPrivate.sendCommand(new byte[] {LOGGING.id, READOUT_PAGE_COMPLETED, (byte) 1});
        }
        mwPrivate.sendCommand(new byte[] {LOGGING.id, REMOVE_ENTRIES, (byte) 0xff, (byte) 0xff, (byte) 0xff, (byte) 0xff});
    }

    Future<void> queryTime() {
        queryTimeTask = new TimedTask<>();
        return queryTimeTask.execute("Did not receive log reference response within %dms", Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(new byte[] { Constant.Module.LOGGING.id, Util.setRead(LoggingImpl.TIME) }));
    }

    Future<Queue<DataLogger>> queueLoggers(Queue<DataTypeBase> producers) {
        final Queue<DataLogger> loggers = new LinkedList<>();
        final Capture<Boolean> terminate = new Capture<>(false);

        return Task.forResult(null).continueWhile(() -> !terminate.get() && !producers.isEmpty(), ignored -> {
            final DataLogger next = new DataLogger(producers.poll());
            final byte[] eventConfig= next.source.eventConfig;

            final byte nReqLogIds= (byte) ((next.source.attributes.length() - 1) / LOG_ENTRY_SIZE + 1);
            final Capture<Byte> remainder= new Capture<>(next.source.attributes.length());
            final Capture<Byte> i = new Capture<>((byte) 0);

            return Task.forResult(null).continueWhile(() -> !terminate.get() && i.get() < nReqLogIds, ignored2 -> {
                final int entrySize= Math.min(remainder.get(), LOG_ENTRY_SIZE), entryOffset= LOG_ENTRY_SIZE * i.get() + next.source.attributes.offset;

                final byte[] command= new byte[6];
                command[0]= LOGGING.id;
                command[1]= TRIGGER;
                System.arraycopy(eventConfig, 0, command, 2, eventConfig.length);
                command[5]= (byte) (((entrySize - 1) << 5) | entryOffset);

                return createLoggerTask.execute("Did not receive log id within %dms", Constant.RESPONSE_TIMEOUT,
                        () -> mwPrivate.sendCommand(command)
                ).continueWithTask(task -> {
                    if (task.isFaulted()) {
                        terminate.set(true);
                        return Task.<Void>forError(new TaskTimeoutException(task.getError(), next));
                    }

                    next.addId(task.getResult()[2]);
                    i.set((byte) (i.get() + 1));
                    remainder.set((byte) (remainder.get() - LOG_ENTRY_SIZE));

                    return Task.forResult(null);
                });
            }).onSuccessTask(ignored2 -> {
                loggers.add(next);
                next.register(dataLoggers);
                return Task.forResult(null);
            });
        }).continueWithTask(task -> {
            if (task.isFaulted()) {
                boolean taskTimeout = task.getError() instanceof TaskTimeoutException;
                if (taskTimeout) {
                    loggers.add((DataLogger) ((TaskTimeoutException) task.getError()).partial);
                }
                while(!loggers.isEmpty()) {
                    loggers.poll().remove(LoggingImpl.this.mwPrivate);
                }
                return Task.forError(taskTimeout ? (Exception) task.getError().getCause() : task.getError());
            }

            return Task.forResult(loggers);
        });
    }


    void processLogData(Uint8List logEntry) {
        final byte logId= (byte) (logEntry[0] & 0x1f), resetUid = (byte) (((logEntry[0] & ~0x1f) >> 5) & 0x7);

        byte[] padded= new byte[8];
        System.arraycopy(logEntry, 1, padded, 0, 4);
        long tick= ByteBuffer.wrap(padded).order(ByteOrder.LITTLE_ENDIAN).getLong(0);

        if (!rollbackTimestamps.containsKey(resetUid) || rollbackTimestamps.get(resetUid) < tick) {
            final byte[] logData = Arrays.copyOfRange(logEntry, 5, logEntry.length);
            final Calendar realTimestamp = computeTimestamp(resetUid, tick);

            if (dataLoggers.containsKey(logId)) {
                dataLoggers.get(logId).handleLogMessage(mwPrivate, logId, realTimestamp, logData, errorHandler);
            } else if (errorHandler != null) {
                errorHandler.receivedError(DownloadError.UNKNOWN_LOG_ENTRY, logId, realTimestamp, logData);
            }
        }
    }

    DateTime computeTimestamp(int resetUid, int tick) {
        TimeReference reference= logReferenceTicks.containsKey(resetUid) ? logReferenceTicks.get(resetUid) : latestReference;

        if (lastTimestamp.containsKey(resetUid) && lastTimestamp.get(resetUid) > tick) {
            long diff = (tick - lastTimestamp.get(resetUid)) & 0xffffffffL;
            long offset = diff + (lastTimestamp.get(resetUid) - reference.tick);
            reference.timestamp.setTimeInMillis(reference.timestamp.getTimeInMillis() + (long) (offset * TICK_TIME_STEP));
            reference.tick = tick;

            if (rollbackTimestamps.containsKey(resetUid)) {
                rollbackTimestamps.put(resetUid, tick);
            }
        }
        lastTimestamp.put(resetUid, tick);

        long offset = (long) ((tick - reference.tick) * TICK_TIME_STEP);
        final Calendar timestamp= (Calendar) reference.timestamp.clone();
        timestamp.setTimeInMillis(timestamp.getTimeInMillis() + offset);

        return timestamp;
    }

    Future<Iterable<DataLogger>> queryActiveLoggersInnerAsync(final int id) {
        final Map<DataTypeBase, int> nRemainingLoggers = new HashMap<>();
        final Capture<Byte> offset = new Capture<>();
        final Capture<byte[]> response = new Capture<>();
        final DataProcessorImpl dataprocessor = (DataProcessorImpl) mwPrivate.getModules().get(DataProcessor.class);

        final Deque<Byte> fuserIds = new LinkedList<>();
        final Deque<Pair<DataTypeBase, ProcessorEntry>> fuserConfigs = new LinkedList<>();
        final Capture<Continuation<Deque<ProcessorEntry>, Task<DataTypeBase>>> onProcessorSynced = new Capture<>();

        onProcessorSynced.set(task -> {
            Deque<ProcessorEntry> result = task.getResult();
            ProcessorEntry first = result.peek();
            DataTypeBase type = guessLogSource(mwPrivate.getDataTypes(), new Tuple3<>(first.source[0], first.source[1], first.source[2]), first.offset, first.length);

            byte revision = mwPrivate.lookupModuleInfo(DATA_PROCESSOR).revision;
            while(!result.isEmpty()) {
                ProcessorEntry current = result.poll();
                if (current.config[0] == DataProcessorConfig.Fuser.ID) {
                    for(int i = 0; i < (current.config[1] & 0x1f); i++) {
                        fuserIds.push(current.config[i + 2]);
                    }
                    fuserConfigs.push(new Pair<>(type, current));;
                } else {
                    DataProcessorConfig config = DataProcessorConfig.from(mwPrivate.getFirmwareVersion(), revision, current.config);
                    Pair<? extends DataTypeBase, ? extends DataTypeBase> next = type.dataProcessorTransform(config,
                            (DataProcessorImpl) mwPrivate.getModules().get(DataProcessor.class));

                    next.first.eventConfig[2] = current.id;
                    if (next.second != null) {
                        next.second.eventConfig[2] = current.id;
                    }
                    dataprocessor.addProcessor(current.id, next.second, type, config);
                    type = next.first;
                }
            }

            if (fuserIds.size() == 0) {
                while(fuserConfigs.size() != 0) {
                    Pair<DataTypeBase, ProcessorEntry> top = fuserConfigs.poll();
                    DataProcessorConfig config = DataProcessorConfig.from(mwPrivate.getFirmwareVersion(), revision, top.second.config);
                    Pair<? extends DataTypeBase, ? extends DataTypeBase> next = top.first.dataProcessorTransform(config,
                            (DataProcessorImpl) mwPrivate.getModules().get(DataProcessor.class));

                    next.first.eventConfig[2] = top.second.id;
                    if (next.second != null) {
                        next.second.eventConfig[2] = top.second.id;
                    }
                    dataprocessor.addProcessor(top.second.id, next.second, top.first, config);

                    type = next.first;
                }
                return Task.forResult(type);
            } else {
                return dataprocessor.pullChainAsync(fuserIds.poll()).onSuccessTask(onProcessorSynced.get());
            }
        });

        return syncLoggerConfigTask.execute("Did not receive logger config for id=" + id + " within %dms", Constant.RESPONSE_TIMEOUT,
                () -> mwPrivate.sendCommand(Uint8List.fromList([0x0b, Util.setRead(TRIGGER), id]))
        ).onSuccessTask(task -> {
            response.set(task.getResult());
            if (response.get().length > 2) {
                offset.set((byte) (response.get()[5] & 0x1f));
                byte length = (byte) (((response.get()[5] >> 5) & 0x3) + 1);

                if (response.get()[2] == DATA_PROCESSOR.id && (response.get()[3] == DataProcessorImpl.NOTIFY || Util.clearRead(response.get()[3]) == DataProcessorImpl.STATE)) {
                    return dataprocessor.pullChainAsync(response.get()[4]).onSuccessTask(onProcessorSynced.get());
                } else {
                    return Task.forResult(guessLogSource(mwPrivate.getDataTypes(), new Tuple3<>(response.get()[2], response.get()[3], response.get()[4]), offset.get(), length));
                }
            } else {
                return Task.cancelled();
            }
        }).onSuccessTask(task -> {
            DataTypeBase dataTypeBase = task.getResult();

            if (response.get()[2] == DATA_PROCESSOR.id && Util.clearRead(response.get()[3]) == DataProcessorImpl.STATE) {
                dataTypeBase = dataprocessor.lookupProcessor(response.get()[4]).state;
            }

            if (!nRemainingLoggers.containsKey(dataTypeBase) && dataTypeBase.attributes.length() > LOG_ENTRY_SIZE) {
                nRemainingLoggers.put(dataTypeBase, (byte) Math.ceil((float) (dataTypeBase.attributes.length() / LOG_ENTRY_SIZE)));
            }

            DataLogger logger = null;
            for(DataLogger it: dataLoggers.values()) {
                if (Arrays.equals(it.source.eventConfig, dataTypeBase.eventConfig) && it.source.attributes.equals(dataTypeBase.attributes)) {
                    logger = it;
                    break;
                }
            }

            if (logger == null || (offset.get() != 0 && !nRemainingLoggers.containsKey(dataTypeBase))) {
                logger = new DataLogger(dataTypeBase);
            }
            logger.addId(id);
            dataLoggers.put(id, logger);

            if (nRemainingLoggers.containsKey(dataTypeBase)) {
                byte remaining = (byte) (nRemainingLoggers.get(dataTypeBase) - 1);
                nRemainingLoggers.put(dataTypeBase, remaining);
                if (remaining < 0) {
                    nRemainingLoggers.remove(dataTypeBase);
                }
            }
            return Task.forResult(null);
        }).continueWithTask(task -> {
            if (!task.isFaulted()) {
                byte nextId = (byte) (id + 1);
                if (nextId < mwPrivate.lookupModuleInfo(LOGGING).extra[0]) {
                    return queryActiveLoggersInnerAsync(nextId);
                }
                Collection<DataLogger> orderedLoggers = new ArrayList<>();
                for(Byte it: new TreeSet<>(dataLoggers.keySet())) {
                    if (!orderedLoggers.contains(dataLoggers.get(it))) {
                        orderedLoggers.add(dataLoggers.get(it));
                    }
                }
                return Task.forResult(orderedLoggers);
            }
            return Task.forError(task.getError());
        });
    }
    Future<Iterable<DataLogger>> queryActiveLoggersAsync() {
        placeholder = new HashMap<>();
        return queryActiveLoggersInnerAsync((byte) 0);
    }
}
