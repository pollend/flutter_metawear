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
import 'dart:core';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_metawear/impl/platform/BtleGatt.dart';
import 'package:flutter_metawear/impl/platform/IO.dart';
import 'package:flutter_metawear/impl/platform/BtleGattCharacteristic.dart';
import 'package:flutter_metawear/impl/platform/DeviceInformationService.dart';

abstract class MwBridge {
 void disconnected();
 void sendMockResponse(Uint8List response);
}

/**
 * Created by etsai on 8/31/16.
 */
class JunitPlatform implements IO, BtleGatt {
    final File RES_PATH = new File(new File("src", "test"), "res");
    final ScheduledExecutorService SCHEDULED_TASK_THREADPOOL = Executors.newSingleThreadScheduledExecutor();

    int nConnects = 0, nDisconnects = 0;
    MetaWearBoardInfo boardInfo= MetaWearBoardInfo();
    String firmware= "1.2.3", boardStateSuffix;
    bool delayModuleInfoResponse= false;
    bool deserializeModuleInfo= false;
    final bool serializeModuleInfo = false;
    bool enableMetaBootState = false;
    bool delayReadDevInfo = false;
    final Map<int, Uint8List> customModuleInfo= Map();
    final Map<int, Uint8List> customResponses = Map();

    int maxProcessors= 28, maxLoggers= 8, maxTimers= 8, maxEvents= 28, maxModule = -1;
    int timerId= 0, eventId= 0, loggerId= 0, dataProcessorId= 0, macroId = 0;
    final MwBridge bridge;
    final List<Uint8List> commandHistory = [], connectCmds = [];
    final List<BtleGattCharacteristic> gattCharReadHistory = [];
    NotificationListener notificationListener;
    DisconnectHandler dcHandler;

    JunitPlatform(MwBridge bridge) {
        this.bridge= bridge;
    }

    void addCustomModuleInfo(byte[] info) {
        customModuleInfo.put(info[0], info);
    }
    void removeCustomModuleInfo(byte id) {
        customModuleInfo.remove(id);
    }
    void addCustomResponse(byte[] command, byte[] response) {
        customResponses.put(Arrays.hashCode(command), response);
    }

    void scheduleMockResponse(final byte[] response) {
        SCHEDULED_TASK_THREADPOOL.schedule(() -> bridge.sendMockResponse(response), 20, TimeUnit.MILLISECONDS);
    }

    void scheduleTask(Runnable r, long timeout) {
        SCHEDULED_TASK_THREADPOOL.schedule(r, timeout, TimeUnit.MILLISECONDS);
    }

    @override
    void localSave(String key, byte[] data) throws IOException {
        String prefix = key.substring(key.lastIndexOf(".") + 1).toLowerCase();
        if (!prefix.equals("board_info") || serializeModuleInfo) {
            FileOutputStream fos = new FileOutputStream(String.format(Locale.US, "build/%s_%s", prefix, boardStateSuffix));
            fos.write(data);
            fos.close();
        }
    }

    @override
    Stream<int> localRetrieve(String key) throws IOException {
        String prefix = key.substring(key.lastIndexOf(".") + 1).toLowerCase();
        if (prefix.equals("board_info") && deserializeModuleInfo) {
            return new FileInputStream(new File(RES_PATH, "board_module_info"));
        }
        return boardStateSuffix != null ?
                new FileInputStream(new File(RES_PATH, String.format(Locale.US, "board_state_%s", boardStateSuffix))) :
                null;
    }

    @override
    Future<void> writeCharacteristicAsync(BtleGattCharacteristic gattCharr, WriteType writeType, byte[] value) {
        if (!customResponses.isEmpty()) {
            for (int i = 2; i < Math.min(3, value.length) + 1; i++) {
                byte[] prefix = new byte[i];
                System.arraycopy(value, 0, prefix, 0, prefix.length);

                int hash = Arrays.hashCode(prefix);
                if (customResponses.containsKey(hash)) {
                    commandHistory.add(value);
                    scheduleMockResponse(customResponses.get(hash));
                    return Task.forResult(null);
                }
            }
        }

        if (value[1] == (byte) 0x80) {
            connectCmds.add(value);

            if (maxModule == -1 || value[0] <= maxModule) {
                byte[] response = customModuleInfo.containsKey(value[0]) ?
                        customModuleInfo.get(value[0]) :
                        boardInfo.moduleResponses.get(value[0]);

                if (delayModuleInfoResponse) {
                    scheduleMockResponse(response);
                } else {
                    bridge.sendMockResponse(response);
                }
            }
        } else if (value[0] == (byte) 0xb && value[1] == (byte) 0x84) {
            connectCmds.add(value);
            scheduleMockResponse(new byte[] {0x0b, (byte) 0x84, 0x15, 0x04, 0x00, 0x00, 0x05});
        } else {
            commandHistory.add(value);

            if (eventId < maxEvents && value[0] == 0xa && value[1] == 0x3) {
                byte[] response= {value[0], 0x2, eventId};
                eventId++;
                scheduleMockResponse(response);
            } else if (timerId < maxTimers && value[0] == 0xc && value[1] == 0x2) {
                byte[] response= {value[0], 0x2, timerId};
                timerId++;
                scheduleMockResponse(response);
            } else if (loggerId < maxLoggers && value[0] == 0xb && value[1] == 0x2) {
                byte[] response= {value[0], 0x2, loggerId};
                loggerId++;
                scheduleMockResponse(response);
            } else if (dataProcessorId < maxProcessors && value[0] == 0x9 && value[1] == 0x2) {
                byte[] response = {value[0], 0x2, dataProcessorId};
                dataProcessorId++;
                scheduleMockResponse(response);
            } else if (value[0] == 0xf && value[1] == 0x2) {
                byte[] response = {value[0], 0x2, macroId};
                macroId++;
                scheduleMockResponse(response);
            } else if (value[0] == (byte) 0xb && value[1] == (byte) 0x85) {
                bridge.sendMockResponse(new byte[] {0x0b, (byte) 0x85, (byte) 0x9e, 0x01, 0x00, 0x00});
            }
        }

        return Task.forResult(null);
    }

//    @override
//    Future<Uint8List> readCharacteristicAsync(BtleGattCharacteristic gattChar) {
//        gattCharReadHistory.add(gattChar);
//        if (gattChar.equals(DeviceInformationService.FIRMWARE_REVISION)) {
//            return Task.delay(20L).continueWithTask(task -> Task.forResult(firmware.getBytes()));
//        } else if (gattChar.equals(DeviceInformationService.HARDWARE_REVISION)) {
//            return Task.delay(20L).continueWithTask(task -> Task.forResult(boardInfo.hardwareRevision));
//        } else if (gattChar.equals(DeviceInformationService.MODEL_NUMBER)) {
//            return Task.delay(20L).continueWithTask(task -> Task.forResult(boardInfo.modelNumber));
//        } else if (gattChar.equals(DeviceInformationService.MANUFACTURER_NAME)) {
//            return Task.delay(20L).continueWithTask(task -> delayReadDevInfo ? Task.forError(new TimeoutException("Reading gatt characteristic timed out")) : Task.forResult(boardInfo.manufacturer));
//        } else if (gattChar.equals(DeviceInformationService.SERIAL_NUMBER)) {
//            return Task.delay(20L).continueWithTask(task -> delayReadDevInfo ? Task.forError(new TimeoutException("Reading gatt characteristic timed out")) : Task.forResult(boardInfo.serialNumber));
//        }
//
//        return Task.forResult(null);
//    }

    @override
    Future<void> enableNotificationsAsync(BtleGattCharacteristic characteristic, NotificationListener listener) {
        if (enableMetaBootState && !characteristic.serviceUuid.equals(MetaWearBoard.METABOOT_SERVICE)) {
            return Task.forError(new IllegalStateException("Service " + characteristic.serviceUuid.toString() + " does not exist"));
        }
        notificationListener = listener;
        return Task.forResult(null);
    }

    @override
    void onDisconnect(DisconnectHandler handler) {
        dcHandler = handler;
    }

    @override
    bool serviceExists(UUID serviceUuid) {
        return enableMetaBootState && serviceUuid.equals(MetaWearBoard.METABOOT_SERVICE) ||
                serviceUuid.equals(MetaWearBoard.METAWEAR_GATT_SERVICE);
    }

    Future<Uint8List> test() => Future.delayed(Duration(milliseconds: 20),() => Uint8List.fromList(Utf8Encoder().convert(firmware)));


    Future<Uint8List> _readCharacteristicAsync(BtleGattCharacteristic gattChar) {
        gattCharReadHistory.add(gattChar);
        if (gattChar == DeviceInformationService.FIRMWARE_REVISION) {
            return Future.delayed(Duration(milliseconds: 20), () =>
                Uint8List.fromList(Utf8Encoder().convert(firmware)));
        } else if (gattChar == DeviceInformationService.HARDWARE_REVISION) {
            return Future.delayed(Duration(milliseconds: 20), () =>
                Uint8List.fromList(
                    Utf8Encoder().convert(boardInfo.hardwareRevision)));
        } else if (gattChar == DeviceInformationService.MODEL_NUMBER) {
            return Future.delayed(Duration(milliseconds: 20), () =>
                Uint8List.fromList(
                    Utf8Encoder().convert(boardInfo.modelNumber)));
        } else if (gattChar == DeviceInformationService.MANUFACTURER_NAME) {
            return Future.delayed(Duration(milliseconds: 20), () =>
            delayReadDevInfo == null
                ? throw new Exception("Reading gatt characterstic timed out")
                : boardInfo.manufacturer);
        } else if (gattChar == DeviceInformationService.SERIAL_NUMBER) {
            return Future.delayed(Duration(milliseconds: 20), () =>
            delayReadDevInfo
                ? throw new Exception("Reading gatt characterstic timed out")
                : boardInfo.serialNumber);
        }
        return Future(() => null);
    }

    @override
    Future<List<Uint8List>> readCharacteristicAsync(List<BtleGattCharacteristic> characteristics) {
        final List<Future<Uint8List>> tasks = List();
        for(BtleGattCharacteristic it in characteristics) {
            tasks.add(_readCharacteristicAsync(it));
        }
        return Future.wait(tasks);
    }

    @override
    Future<void> localDisconnectAsync() {
        nDisconnects++;
        bridge.disconnected();
        return Future(() => null);
    }

    @override
    Future<void> remoteDisconnectAsync() {
        return localDisconnectAsync();
    }

    @override
    Future<void> connectAsync() {
        nConnects++;
        return Task.forResult(null);
    }

    @override
    Future<int> readRssiAsync() {
        TaskCompletionSource<Integer> source= new TaskCompletionSource<>();
        source.trySetError(new UnsupportedOperationException("Reading rssi not supported in JUnit tests"));
        return source.getTask();
    }

    @override
    Future<File> downloadFileAsync(String srcUrl, String dest) {
        if (srcUrl.endsWith("firmware.zip") || srcUrl.endsWith("bl.zip") || srcUrl.endsWith("sd_bl.zip")) {
            return Task.forResult(new File(dest));
        } else if (srcUrl.endsWith("info2.json")) {
            return Task.forResult(new File(RES_PATH, "info2.json"));
        }
        throw new UnsupportedOperationException("Not yet implemented");
    }

    @override
    File findDownloadedFile(String filename) {
        // create a dummy File object
        return new File(RES_PATH, filename);
    }

    @override
    void logWarn(String tag, String message) {
        System.out.println(String.format(Locale.US, "%s: %s", tag, message));
    }

    @override
    void logWarn(String tag, String message, Throwable tr) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        tr.printStackTrace(pw);

        System.out.println(String.format(Locale.US, "%s: %s%n%s", tag, message, sw.toString()));
    }

    List<Uint8List> getConnectCommands() {
        byte[][] cmdArray= new byte[connectCmds.size()][];
        for(int i= 0; i < connectCmds.size(); i++) {
            cmdArray[i]= connectCmds.get(i);
        }

        return cmdArray;
    }

    List<Uint8List> getCommands() {
        return getCommands(0, commandHistory.size());
    }

    List<Uint8List> getCommands(int start, int end) {
        byte[][] cmdArray= new byte[end - start][];
        for(int i= start; i < end; i++) {
            cmdArray[i - start]= commandHistory.get(i);
        }

        return cmdArray;
    }

    List<Uint8List> getCommands(int start) {
        return getCommands(start, commandHistory.size());
    }

    Uint8List getLastCommand() {
        return commandHistory.isEmpty() ? null : commandHistory.get(commandHistory.size() - 1);
    }

    List<Uint8List> getLastCommands(int count) {
        byte[][] cmdArray= new byte[count][];
        for(int i= 0; i < count; i++) {
            int index= commandHistory.size() - (count - i);
            cmdArray[i]= commandHistory.get(index);
        }

        return cmdArray;
    }

    List<BtleGattCharacteristic> getGattCharReadHistory() {
        BtleGattCharacteristic[] array = new BtleGattCharacteristic[gattCharReadHistory.size()];
        gattCharReadHistory.toArray(array);
        return array;
    }
}
