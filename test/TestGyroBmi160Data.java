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

import com.mbientlab.metawear.module.GyroBmi160;
import com.mbientlab.metawear.data.AngularVelocity;
import com.mbientlab.metawear.module.GyroBmi160.Range;

import org.junit.Before;
import org.junit.Test;

import bolts.Capture;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;

/**
 * Created by etsai on 10/2/16.
 */

public class TestGyroBmi160Data extends UnitTestBase {
    private GyroBmi160 gyroBmi160;

    @Before
    public void setup() throws Exception {
        junitPlatform.boardInfo = new MetaWearBoardInfo(GyroBmi160.class);
        connectToBoard();

        gyroBmi160= mwBoard.getModule(GyroBmi160.class);
    }

    @Test
    public void start() {
        byte[] expected = new byte[] {0x13, 0x01, 0x01};

        gyroBmi160.start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void stop() {
        byte[] expected = new byte[] {0x13, 0x01, 0x00};

        gyroBmi160.stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void enable() {
        byte[] expected = new byte[] {0x13, 0x02, 0x00, 0x01};

        gyroBmi160.angularVelocity().stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void disable() {
        byte[] expected = new byte[] {0x13, 0x02, 0x01, 0x00};

        gyroBmi160.angularVelocity().start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void interpretData() {
        AngularVelocity expected= new AngularVelocity(Float.intBitsToFloat(0x4383344b), Float.intBitsToFloat(0x43f9bf9c), Float.intBitsToFloat(0xc3f9c190));
        final Capture<AngularVelocity> actual= new Capture<>();

        gyroBmi160.configure()
                .range(Range.FSR_500)
                .commit();
        gyroBmi160.angularVelocity().addRouteAsync(source ->
                source.stream((data, env) -> ((Capture<AngularVelocity>) env[0]).set(data.value(AngularVelocity.class))))
        .continueWith(task -> {
            task.getResult().setEnvironment(0, actual);
            return null;
        });
        sendMockResponse(new byte[] {0x13, 0x05, 0x3e, 0x43, (byte) 0xff, 0x7f, 0x00, (byte) 0x80});

        assertEquals(expected, actual.get());
    }

    @Test
    public void interpretComponentData() {
        float[] expected = new float[] {262.409f, 499.497f, -499.512f};
        final float[] actual= new float[3];

        gyroBmi160.configure()
                .range(Range.FSR_500)
                .commit();
        gyroBmi160.angularVelocity().addRouteAsync(source -> source.split()
                .index(0).stream((data, env) -> ((float[]) env[0])[0] = data.value(Float.class))
                .index(1).stream((data, env) -> ((float[]) env[0])[1] = data.value(Float.class))
                .index(2).stream((data, env) -> ((float[]) env[0])[2] = data.value(Float.class)))
        .continueWith(task -> {
            task.getResult().setEnvironment(0, (Object) actual);
            task.getResult().setEnvironment(1, (Object) actual);
            task.getResult().setEnvironment(2, (Object) actual);
            return null;
        });
        sendMockResponse(new byte[] {0x13, 0x05, 0x3e, 0x43, (byte) 0xff, 0x7f, 0x00, (byte) 0x80});

        assertArrayEquals(expected, actual, 0.001f);
    }

    @Test
    public void subscribe() {
        byte[] expected= new byte[] { 0x13, 0x05, 0x01 };
        gyroBmi160.angularVelocity().addRouteAsync(source -> source.stream(null));

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void unsubscribe() {
        byte[] expected= new byte[] { 0x13, 0x05, 0x00 };
        gyroBmi160.angularVelocity().addRouteAsync(source -> source.stream(null)).continueWith(task -> {
            task.getResult().unsubscribe(0);
            return null;
        });

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }
}
