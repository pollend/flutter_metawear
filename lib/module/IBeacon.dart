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


import 'dart:core';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_metawear/ConfigEditorBase.dart';
import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter_metawear/Configurable.dart';

/**
 * Interface for configuring IBeacon settings
 * @author Eric Tsai
 */
abstract class ConfigEditor extends ConfigEditorBase {
    /**
     * Set the advertising UUID
     * @param adUuid    New advertising UUID
     * @return Calling object
     */
    ConfigEditor uuid(Guid adUuid);
    /**
     * Set the advertising major number
     * @param major    New advertising major number
     * @return Calling object
     */
    ConfigEditor major(int major);
    /**
     * Set the advertising major number
     * @param major    New advertising major number
     * @return Calling object
     */
    ConfigEditor majorAsToken(DataToken major);
    /**
     * Set the advertising minor number
     * @param minor    New advertising minor number
     * @return Calling object
     */
    ConfigEditor minor(int minor);
    /**
     * Set the advertising minor number
     * @param minor    New advertising minor number
     * @return Calling object
     */
    ConfigEditor minorAsToken(DataToken minor);
    /**
     * Set the advertising receiving power
     * @param power    New advertising receiving power
     * @return Calling object
     */
    ConfigEditor rxPower(int power);
    /**
     * Set the advertising transmitting power
     * @param power    New advertising transmitting power
     * @return Calling object
     */
    ConfigEditor txPower(int power);
    /**
     * Set the advertising period
     * @param period    New advertising period, in milliseconds
     * @return Calling object
     */
    ConfigEditor period(int period);
}

/**
 * Wrapper class encapsulating the IBeacon configuration
 * @author Eric Tsai
 */
class Configuration {
    /** Advertising UUID */
     Guid uuid;
    /** Advertising major value */
     int major;
    /** Advertising minor value */
     int minor;
    /** Advertising period */
     int period;
    /** Advertising receiving power */
     int rxPower;
    /** Advertising transmitting power */
     int txPower;

    Configuration.Empty();
    Configuration(this.uuid, this.major, this.minor, this.period, this.rxPower, this.txPower);

    @override
  String toString() {
    // TODO: implement toString
    return sprintf("{uuid: %s, major: %d, minor: %d, rx: %d, tx: %d, period: %d}",[uuid, major, minor, rxPower, txPower, period]);
  }

  @override
  int get hashCode{
        int result = uuid.hashCode;
        result = 31 * result + major;
        result = 31 * result + minor;
        result = 31 * result + period;
        result = 31 * result + rxPower;
        result = 31 * result + txPower;
        return result;
  }

  @override
  bool operator ==(other) {
      if (this == other) return true;
      if (other == null || other is! Configuration) return false;
      Configuration that = other as Configuration;
      return major == that.major && minor == that.minor && period == that.period && rxPower == that.rxPower && txPower == that.txPower && uuid == that.uuid;
  }

}

/**
 * Apple developed protocol for Bluetooth LE proximity sensing
 * @author Eric Tsai
 */
abstract class IBeacon extends Module implements Configurable<ConfigEditor> {
    /**
     * Enable IBeacon advertising.  You will need to disconnect from the board to advertise as an IBeacon
     */
    void enable();
    /**
     * Disable IBeacon advertising
     */
    void disable();

    /**
     * Read the current IBeacon configuration
     * @return Configuration object that will be available when the read operation completes
     */
    Future<Configuration> readConfigAsync();
}
