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


class ModuleType {
    static const Duration RESPONSE_TIMEOUT = Duration(seconds: 1);
    static final int COMMAND_LENGTH = 18,
        MAX_BTLE_LENGTH = COMMAND_LENGTH + 2;

    final int id;
    final String friendlyName;

    const ModuleType._interal(this.id, this.friendlyName);

    static const SWITCH = const ModuleType._interal(0x01, "Switch");
    static const LED = const ModuleType._interal(0x02, "Led");
    static const ACCELEROMETER = const ModuleType._interal(0x03, "Accelerometer");
    static const TEMPERATURE = const ModuleType._interal(0x04, "Temperature");
    static const GPIO = const ModuleType._interal(0x05, "Gpio");
    static const NEO_PIXEL = const ModuleType._interal(0x06, "NeoPixel");
    static const IBEACON = const ModuleType._interal(0x07, "IBeacon");
    static const HAPTIC = const ModuleType._interal(0x08, "Haptic");
    static const DATA_PROCESSOR = const ModuleType._interal(0x09, "DataProcessor");
    static const EVENT = const ModuleType._interal(0x0a, "Event");
    static const LOGGING = const ModuleType._interal(0x0b, "Logging");
    static const TIMER = const ModuleType._interal(0x0c, "Timer");
    static const SERIAL_PASSTHROUGH = const ModuleType._interal(0x0d, "SerialPassthrough");
    static const MACRO = const ModuleType._interal(0x0f, "Macro");
    static const GSR = const ModuleType._interal(0x10, "Conductance");
    static const SETTINGS = const ModuleType._interal(0x11, "Settings");
    static const BAROMETER = const ModuleType._interal(0x12, "Barometer");
    static const GYRO = const ModuleType._interal(0x13, "Gyro");
    static const AMBIENT_LIGHT = const ModuleType._interal(0x14, "AmbientLight");
    static const MAGNETOMETER = const ModuleType._interal(0x15, "Magnetometer");
    static const HUMIDITY = const ModuleType._interal(0x16, "Humidity");
    static const COLOR_DETECTOR = const ModuleType._interal(0x17, "Color");
    static const PROXIMITY = const ModuleType._interal(0x18, "Proximity");
    static const SENSOR_FUSION = const ModuleType._interal(0x19, "SensorFusion");
    static const DEBUG = const ModuleType._interal(0xfe, "Debug");

    static List<ModuleType> entries = List.unmodifiable([
        SWITCH,
        LED,
        ACCELEROMETER,
        TEMPERATURE,
        GPIO,
        NEO_PIXEL,
        IBEACON,
        HAPTIC,
        DATA_PROCESSOR,
        EVENT,
        LOGGING,
        TIMER,
        SERIAL_PASSTHROUGH,
        MACRO,
        GSR,
        SERIAL_PASSTHROUGH,
        BAROMETER,
        GYRO,
        AMBIENT_LIGHT,
        MAGNETOMETER,
        HUMIDITY,
        COLOR_DETECTOR,
        PROXIMITY,
        SENSOR_FUSION,
        DEBUG
    ]);


    static ModuleType lookupEnum(int id) {
        return entries.singleWhere((el) => el.id == id);
    }
}
