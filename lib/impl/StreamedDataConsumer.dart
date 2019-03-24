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

import 'package:flutter_metawear/Subscriber.dart';
import 'package:flutter_metawear/impl/DataProcessorConfig.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/DeviceDataConsumer.dart';
import 'package:flutter_metawear/impl/LoggingImpl.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/module/DataProcessor.dart';
import 'package:flutter_metawear/module/Logging.dart';

import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:flutter_metawear/builder/RouteComponent.dart';
/**
 * Created by etsai on 10/27/16.
 */

class StreamedDataConsumer extends DeviceDataConsumer {


    void Function(Uint8List handler) dataResponseHandler;

    StreamedDataConsumer(DataTypeBase source, Subscriber subscriber) : super(source,subscriber);


    void enableStream(final MetaWearBoardPrivate mwPrivate) {
        addDataHandler(mwPrivate);

        if ((source.eventConfig[1] & 0x80) == 0x0) {
            if (source.eventConfig[2] == DataTypeBase.NO_DATA_ID) {
                if (mwPrivate.numDataHandlers(source.eventConfigAsTuple()) == 1) {
                    mwPrivate.sendCommand(Uint8List.fromList([source.eventConfig[0], source.eventConfig[1], 0x1]));
                }
            } else {
                mwPrivate.sendCommand(Uint8List.fromList([source.eventConfig[0], source.eventConfig[1], 0x1]));
                if (mwPrivate.numDataHandlers(source.eventConfigAsTuple()) == 1) {
                    if (source.eventConfig[0] ==  ModuleType.DATA_PROCESSOR.id && source.eventConfig[1] == DataProcessorImpl.NOTIFY) {
                        mwPrivate.sendCommand(Uint8List.fromList([source.eventConfig[0], DataProcessorImpl.NOTIFY_ENABLE, source.eventConfig[2], 0x1]));
                    }
                }
            }
        } else {
            source.markLive();
        }
    }

    void disableStream(MetaWearBoardPrivate mwPrivate) {
        if ((source.eventConfig[1] & 0x80) == 0x0) {
            if (source.eventConfig[2] == DataTypeBase.NO_DATA_ID) {
                if (mwPrivate.numDataHandlers(source.eventConfigAsTuple()) ==
                    1) {
                    mwPrivate.sendCommand(Uint8List.fromList(
                        [source.eventConfig[0], source.eventConfig[1], 0x0]));
                }
            } else {
                if (mwPrivate.numDataHandlers(source.eventConfigAsTuple()) ==
                    1) {
                    if (source.eventConfig[0] == ModuleType.DATA_PROCESSOR.id &&
                        source.eventConfig[1] == DataProcessorImpl.NOTIFY) {
                        mwPrivate.sendCommand(Uint8List.fromList([
                            source.eventConfig[0],
                            DataProcessorImpl.NOTIFY_ENABLE,
                            source.eventConfig[2],
                            0x0
                        ]));
                    }
                }
            }
        } else {
            if (mwPrivate.numDataHandlers(source.eventConfigAsTuple()) == 1) {
                source.markSilent();
            }
        }

        mwPrivate.removeDataHandler(
            source.eventConfigAsTuple(), dataResponseHandler);
    }

    void addDataHandler(final MetaWearBoardPrivate mwPrivate) {

        if (source.eventConfig[2] != DataTypeBase.NO_DATA_ID) {
            mwPrivate.addDataIdHeader(Tuple2(source.eventConfig[0], source.eventConfig[1]));
        }
        if (dataResponseHandler == null) {
            if (source.attributes.copies > 1) {
                final int dataUnitLength = source.attributes.unitLength();
                dataResponseHandler = (Uint8List response) {
                    DateTime now = DateTime.now();
                    Processor accounter = findParent(mwPrivate.getModules()[DataProcessor] as DataProcessorImpl, source, DataProcessorImpl.TYPE_ACCOUNTER);
                    AccountType accountType = accounter == null ? AccountType.TIME : (accounter.editor.configObj as Accounter).type;
                    for(int i = 0, j = source.eventConfig[2] == DataTypeBase.NO_DATA_ID ? 2 : 3; i< source.attributes.copies && j < response.length; i++, j+= dataUnitLength) {
                        Tuple3<DateTime, int, int> account = fillTimestamp(mwPrivate, accounter, response, j);
                        Uint8List dataRaw = Uint8List(dataUnitLength - (account.item2 - j));
                        dataRaw.setAll(0, response.skip(account.item2));

                        call(source.createMessage(false, mwPrivate, dataRaw, accounter == null ? now : account.item1, accountType == AccountType.TIME ? null : ((Type clazz) => clazz == int ? account.item3 : null)));
                    }
                };
            } else {
                dataResponseHandler = (Uint8List response) {
                    Uint8List dataRaw;

                    if (source.eventConfig[2] == DataTypeBase.NO_DATA_ID) {
                        dataRaw = Uint8List(response.length - 2);
                        dataRaw.setAll(0, response.skip(2));
                    } else {
                        dataRaw = Uint8List(response.length - 3);
                        dataRaw.setAll(0, response.skip(3));
                    }

                    AccountType accountType = AccountType.TIME;
                    Tuple3<DateTime, int, int> account;
                    if (source.eventConfig[0] == ModuleType.DATA_PROCESSOR.id && source.eventConfig[1] == DataProcessorImpl.NOTIFY) {
                        DataProcessorImpl dataprocessor = mwPrivate.getModules()[DataProcessor] as DataProcessorImpl;
                        DataProcessorConfig config = dataprocessor.lookupProcessor(source.eventConfig[2]).editor.configObj;
                        account = fillTimestamp(mwPrivate, dataprocessor.lookupProcessor(source.eventConfig[2]), dataRaw, 0);

                        if (account.item2 > 0) {
                            Uint8List copy = Uint8List(dataRaw.length - account.item2);
                            copy.setAll(0, dataRaw.skip(account.item2));
//                            System.arraycopy(dataRaw, account.second, copy, 0, copy.length);
                            dataRaw = copy;
                            accountType = (config as Accounter).type;
                        }
                    } else {
                        account = new Tuple3(DateTime.now(), 0, 0);
                    }

                   Processor packer = findParent(mwPrivate.getModules()[DataProcessor] as DataProcessorImpl, source, DataProcessorImpl.TYPE_PACKER);
                    if (packer != null) {
                        final int dataUnitLength = packer.editor.source.attributes.unitLength();
                        Uint8List unpacked = Uint8List(dataUnitLength);
                        for(int i = 0, j = 3 + account.item2; i< packer.editor.source.attributes.copies && j < response.length; i++, j+= dataUnitLength) {
//                            System.arraycopy(response, j, unpacked, 0, unpacked.length);
                            unpacked.setAll(0, response.skip(j));
                            call(source.createMessage(false, mwPrivate, unpacked, account.item1, accountType == AccountType.TIME ? null : ((Type clazz) => clazz == int ? account.item3 : null)));
                        }
                    } else {
                        call(source.createMessage(false, mwPrivate, dataRaw, account.item1, accountType == AccountType.TIME ? null :  ((Type clazz) => clazz == int ? account.item3 : null)));
                    }
                };
            }
        }

        mwPrivate.addDataHandler(source.eventConfigAsTuple(), dataResponseHandler);
    }

    static Processor findParent(DataProcessorImpl dataprocessor, DataTypeBase child, int type) {
        if (child.eventConfig[0] == ModuleType.DATA_PROCESSOR.id && child.eventConfig[1] == DataProcessorImpl.NOTIFY) {
            Processor processor = dataprocessor.lookupProcessor(child.eventConfig[2]);
            if (processor.editor.config[0] == type) {
                return processor;
            }

            return findParent(dataprocessor, child.input, type);
        }
        return null;
    }

    static Tuple3<DateTime, int, int> fillTimestamp(MetaWearBoardPrivate mwPrivate, Processor accounter, Uint8List response, int offset) {
        if (accounter != null) {
            DataProcessorConfig config = accounter.editor.configObj;
            if (config is Accounter) {
                int size = (config as Accounter).length;
                Uint8List padded = Uint8List(8);
                padded.setAll(0,response.skip(offset));
//                System.arraycopy(response, offset, padded, 0, size);
                int tick = ByteData.view(padded.buffer).getUint16(0,Endian.little);
//                ByteBuffer.wrap(padded).order(ByteOrder.LITTLE_ENDIAN).getLong(0);

                switch((config as Accounter).type) {
                    case AccountType.COUNT: {
                        return Tuple3(DateTime.now(), size + offset, tick);
                    }
                    case AccountType.TIME: {
                        LoggingImpl logging = mwPrivate.getModules()[Logging] as LoggingImpl;
                        return Tuple3(logging.computeTimestamp(-1, tick), size + offset, tick);
                    }
                }
            }
        }
        return Tuple3(DateTime.now(), offset, 0);
    }
}
