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

import 'package:flutter_metawear/CodeBlock.dart';
import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';
import 'package:flutter_metawear/Observer.dart';
import 'package:flutter_metawear/Route.dart';
import 'package:flutter_metawear/builder/RouteBuilder.dart';
import 'package:flutter_metawear/impl/DataTypeBase.dart';
import 'package:flutter_metawear/impl/JseMetaWearBoard.dart';
import 'package:flutter_metawear/impl/ModuleInfo.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Version.dart';
import 'package:flutter_metawear/module/Timer.dart';

import 'package:tuple/tuple.dart';

class WithDataToken{
    final DataToken token;
    final int dest;

  WithDataToken(this.token, this.dest);
}

/**
 * Created by etsai on 8/31/16.
 */
abstract class MetaWearBoardPrivate {
    Future<void> boardDisconnect();
    void sendCommand(Uint8List command,[WithDataToken token]);
//    void sendCommand(Uint8List command, int dest, DataToken input);

    void sendCommandForModule(ModuleType module, int register, List<int> parameters,[int id]);
//    void sendCommand(Constant.Module module, byte register, byte id, byte ... parameters);

    void tagProducer(String name, DataTypeBase producer);
    DataTypeBase lookupProducer(String name);
    bool hasProducer(String name);
    void removeProducerTag(String name);

    ModuleInfo lookupModuleInfo(ModuleType id);
    List<DataTypeBase> getDataTypes();
    Map<Type, Module> getModules();
    void addDataIdHeader(Tuple2<int, int> key);
    void addDataHandler(Tuple3<int, int, int> key, RegisterResponseHandler handler);
    void addResponseHandler(Tuple2<int, int> key, RegisterResponseHandler handler);
    void removeDataHandler(Tuple3<int, int, int> key, RegisterResponseHandler handler);
    int numDataHandlers(Tuple3<int, int, int> key);

    void removeProcessor(bool sync, int id);
    void removeRoute(int id);
    void removeEventManager(int id);

    Future<Route> queueRouteBuilder(RouteBuilder builder, String producerTag);
    Future<ScheduledTask> queueTaskManager(CodeBlock mwCode, Uint8List timerConfig);
    Future<Observer> queueEvent(DataTypeBase owner, CodeBlock codeBlock);

    void logWarn(String message);

    Version getFirmwareVersion();
}
