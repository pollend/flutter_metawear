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
import 'package:flutter_metawear/module/BarometerBosch.dart' as BarometerBosch;

/**
 * Supported stand by times on the BMP280 sensor
 * @author Eric Tsai
 */
class StandbyTime {
    /** 0.5ms */
    static const TIME_0_5 = StandbyTime._(0.5,0);

    /** 62.5ms */
    static const TIME_62_5 = StandbyTime._(62.5,1);

    /** 125ms */
    static const TIME_125 = StandbyTime._(125,2);

    /** 250ms */
    static const TIME_250 = StandbyTime._(250,3);

    /** 500ms */
    static const TIME_500 = StandbyTime._(500,4);

    /** 1000ms */
    static const TIME_1000 = StandbyTime._(1000,5);

    /** 2000ms */
    static const TIME_2000 = StandbyTime._(2000,6);

    /** 4000ms */
    static const TIME_4000 = StandbyTime._(4000,7);

    final double time;
    final int index;

    const StandbyTime._(this.time,this.index);

    static List<StandbyTime> _entries = [
        TIME_0_5,
        TIME_62_5,
        TIME_125,
        TIME_250,
        TIME_500,
        TIME_1000,
        TIME_2000,
        TIME_4000
    ];


    static List<double> get times => _entries.map((t) => t.time);

}

/**
 * Barometer configuration editor specific to the BMP280 barometer
 * @author Eric Tsai
 */
abstract class ConfigEditor extends BarometerBosch.ConfigEditor<ConfigEditor> {
/**
 * Set the standby time
 * @param time    New standby time
 * @return Calling object
 */
ConfigEditor standbyTime(StandbyTime time);
}

/**
 * Extension of the {@link BarometerBosch} interface providing finer control over the barometer on
 * the BMP280 pressure sensor
 * @author Eric Tsai
 */
abstract class BarometerBmp280 extends BarometerBosch.BarometerBosch {


    /**
     * Configures BMP280 barometer
     * @return Editor object specific to the BMP280 barometer
     */
    @override
    ConfigEditor configure();
}
