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

package com.mbientlab.metawear;

import com.mbientlab.metawear.module.AccelerometerBmi160;

import org.junit.Before;
import org.junit.Test;

import bolts.Capture;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;

/**
 * Created by etsai on 11/14/16.
 */

public class TestBmi160StepCounterData extends UnitTestBase {
    private AccelerometerBmi160.StepCounterDataProducer counter;

    @Before
    public void setup() throws Exception {
        junitPlatform.boardInfo = new MetaWearBoardInfo(AccelerometerBmi160.class);
        connectToBoard();

        counter = mwBoard.getModule(AccelerometerBmi160.class).stepCounter();
    }

    @Test
    public void handleResponse() {
        final Capture<Short> actual = new Capture<>();
        short expected= 43;

        counter.addRouteAsync(source -> source.stream((data, env) -> ((Capture<Short>) env[0]).set(data.value(Short.class))))
                .continueWith(task -> {
                    task.getResult().setEnvironment(0, actual);
                    return null;
                });

        sendMockResponse(new byte[] {0x03, (byte) 0x9a, 0x2b, 0x00});
        assertEquals(expected, actual.get().shortValue());
    }

    @Test
    public void read() {
        byte[] expected = new byte[] {0x03, (byte) 0x9a};

        counter.addRouteAsync(source -> source.stream(null)).continueWith(task -> {
            counter.read();
            return null;
        });

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void silentRead() {
        byte[] expected = new byte[] {0x03, (byte) 0xda};
        counter.read();

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }
}
