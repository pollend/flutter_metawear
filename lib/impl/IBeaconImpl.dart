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

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/impl/MetaWearBoardPrivate.dart';
import 'package:flutter_metawear/impl/ModuleImplBase.dart';
import 'package:flutter_metawear/impl/ModuleType.dart';
import 'package:flutter_metawear/impl/Util.dart';

import 'package:flutter_metawear/module/IBeacon.dart';
import 'package:tuple/tuple.dart';

import 'dart:typed_data';

class _ConfigEditor extends ConfigEditor{
  Guid newUuid= null;
  int newMajor= null, newMinor= null, newPeriod = null;
  int newRxPower= null, newTxPower= null;
  DataToken majorToken = null, newMinorDataToken = null;
  final MetaWearBoardPrivate mwPrivate;

  _ConfigEditor(this.mwPrivate);

  @override
  void commit() {
    if (newUuid != null) {
      mwPrivate.sendCommandForModule(
          ModuleType.IBEACON, IBeaconImpl.AD_UUID, newUuid.toByteArray());
    }

    if (newMajor != null) {
      Uint8List result = Uint8List(2);
      ByteData.view(result.buffer).setInt16(0, newMajor, Endian.little);
      mwPrivate.sendCommandForModule(
          ModuleType.IBEACON, IBeaconImpl.MAJOR, result);
    } else if (majorToken != null) {
      Uint8List result = Uint8List(4);
      ByteData data = ByteData.view(result.buffer);
      data.setInt8(0, ModuleType.IBEACON.id);
      data.setInt16(1, IBeaconImpl.MAJOR);
      data.setInt16(2, 0, Endian.little);

      mwPrivate.sendCommand(result, WithDataToken(majorToken, 0));
    }

    if (newMinor != null) {
      Uint8List result = Uint8List(2);
      ByteData.view(result.buffer).setInt16(0, newMinor, Endian.little);
      mwPrivate.sendCommandForModule(
          ModuleType.IBEACON, IBeaconImpl.MINOR, result);
    } else if (newMinorDataToken != null) {
      Uint8List result = Uint8List(4);
      ByteData data = ByteData.view(result.buffer);
      data.setInt8(0, ModuleType.IBEACON.id);
      data.setInt16(1, IBeaconImpl.MINOR);
      data.setInt16(2, 0, Endian.little);

      this.mwPrivate.sendCommand(result, WithDataToken(newMinorDataToken, 0));
    }

    if (newRxPower != null) {
      mwPrivate.sendCommand(Uint8List.fromList(
          [ModuleType.IBEACON.id, IBeaconImpl.RX, newRxPower]));
    }

    if (newTxPower != null) {
      mwPrivate.sendCommand(Uint8List.fromList(
          [ModuleType.IBEACON.id, IBeaconImpl.TX, newTxPower]));
    }

    if (newPeriod != null) {
      Uint8List result = Uint8List(2);
      ByteData.view(result.buffer).setInt16(0, newPeriod, Endian.little);

      mwPrivate.sendCommandForModule(
          ModuleType.IBEACON, IBeaconImpl.PERIOD, result);
    }
  }

  @override
  ConfigEditor major(int major) {
    // TODO: implement major
    return null;
  }

  @override
  ConfigEditor majorAsToken(DataToken major) {
    this.majorToken = major;
    return this;
  }

  @override
  ConfigEditor minor(int minor) {
    this.newMinor = minor;
    return this;
  }

  @override
  ConfigEditor minorAsToken(DataToken minor) {
    this.newMinorDataToken = minor;
    return this;
  }

  @override
  ConfigEditor period(int period) {
    this.newPeriod = period;
    return this;
  }

  @override
  ConfigEditor rxPower(int power) {
    this.newRxPower= power;
    return this;
  }

  @override
  ConfigEditor txPower(int power) {
    this.newTxPower = power;
    return this;
  }

  @override
  ConfigEditor uuid(Guid adUuid) {
    this.newUuid = adUuid;
    return this;
  }

}
/**
 * Created by etsai on 9/18/16.
 */
class IBeaconImpl extends ModuleImplBase implements IBeacon {
  static const ENABLE = 0x1,
      AD_UUID = 0x2,
      MAJOR = 0x3,
      MINOR = 0x4,
      RX = 0x5,
      TX = 0x6,
      PERIOD = 0x7;

  final StreamController<Uint8List> _streamController = StreamController<Uint8List>();

  IBeaconImpl(MetaWearBoardPrivate mwPrivate) : super(mwPrivate);

  @override
  void init() {
    for (int id in Uint8List.fromList(
        [AD_UUID, MAJOR, MINOR, RX, TX, PERIOD])) {
      this.mwPrivate.addResponseHandler(Tuple2(ModuleType.IBEACON.id, Util.setRead(id)), (Uint8List response) => {
        _streamController.add(response)
      });
    }
  }

  @override
  ConfigEditor configure() {
    return _ConfigEditor(mwPrivate);
  }

  @override
  void enable() {
    mwPrivate.sendCommand(
        Uint8List.fromList([ModuleType.IBEACON.id, ENABLE, 1]));
  }

  @override
  void disable() {
    mwPrivate.sendCommand(
        Uint8List.fromList([ModuleType.IBEACON.id, ENABLE, 0]));
  }

  @override
  Future<Configuration> readConfigAsync() async {
    Guid ad = Guid.empty();
    int major = null,
        minor = null;
    int rxPower = null,
        txPower = null;
    int period = null;
    TimeoutException exception;

    Stream<Uint8List> stream = _streamController.stream.timeout(
        ModuleType.RESPONSE_TIMEOUT);
    StreamIterator<Uint8List> iterator = StreamIterator(stream);

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(AD_UUID)])); //request uuid
    exception = TimeoutException(
        "Did not receive ibeacon UUID", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    ad.toByteArray().setAll(0, iterator.current.skip(2));

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(MAJOR)])); //request major
    exception = TimeoutException(
        "Did not receive iBeacon major value", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    major = ByteData.view(iterator.current.buffer).getInt16(2);

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(MINOR)])); //request Minor
    exception = TimeoutException(
        "Did not receive iBeacon minor value", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    minor = ByteData.view(iterator.current.buffer).getInt16(2);

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(RX)])); //request Rx
    exception = TimeoutException(
        "Did not receive iBeacon rx value", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    rxPower = iterator.current[2];

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(TX)])); //request Tx
    exception = TimeoutException(
        "Did not receive iBeacon tx value", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    txPower = iterator.current[2];

    mwPrivate.sendCommand(Uint8List.fromList(
        [ModuleType.IBEACON.id, Util.setRead(PERIOD)])); //request Period
    exception = TimeoutException(
        "Did not receive iBeacon period value", ModuleType.RESPONSE_TIMEOUT);
    if (await iterator.moveNext().catchError((e) => throw exception,
        test: (e) => e is TimeoutException) == false)
      throw exception;
    period = ByteData.view(iterator.current.buffer).getInt16(2);
    return Configuration(ad, major, minor, period, rxPower, txPower);
  }
}
