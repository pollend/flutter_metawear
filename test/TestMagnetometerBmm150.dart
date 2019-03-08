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

import com.mbientlab.metawear.module.MagnetometerBmm150;
import com.mbientlab.metawear.data.MagneticField;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

import java.util.ArrayList;
import java.util.Collection;

import bolts.Capture;

import static com.mbientlab.metawear.TestMagnetometerBmm150Config.SLEEP_REV;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

/**
 * Created by etsai on 10/6/16.
 */
@RunWith(Parameterized.class)
public class TestMagnetometerBmm150 extends UnitTestBase {
    @Parameters(name = "revision: {0}")
    public static Collection<Object[]> data() {
        ArrayList<Object[]> parameters= new ArrayList<>();
        parameters.add(new Object[] { (byte) 1 });
        parameters.add(new Object[] { SLEEP_REV });
        return parameters;
    }

    @Parameter
    public byte revision;

    private MagnetometerBmm150 mag;

    @Before
    public void setup() throws Exception {
        junitPlatform.addCustomModuleInfo(new byte[] {0x15, (byte) 0x80, 0x00, revision});
        connectToBoard();

        mag= mwBoard.getModule(MagnetometerBmm150.class);
    }

    @Test
    public void suspend() {
        mag.suspend();

        if (revision == SLEEP_REV) {
            assertArrayEquals(new byte[] {0x15, 0x01, 0x02}, junitPlatform.getLastCommand());
        } else {
            assertNull(junitPlatform.getLastCommand());
        }
    }

    @Test
    public void enableBFieldSampling() {
        byte[] expected= new byte[] {0x15, 0x02, 0x01, 0x00};

        mag.magneticField().start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void disableBFieldSampling() {
        byte[] expected= new byte[] {0x15, 0x02, 0x00, 0x01};

        mag.magneticField().stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void globalStart() {
        byte[] expected= new byte[] {0x15, 0x01, 0x01};

        mag.start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void globalStop() {
        byte[] expected= new byte[] {0x15, 0x01, 0x00};

        mag.stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void bFieldSubscribe() {
        byte[] expected= new byte[] {0x15, 0x05, 0x01};
        mag.magneticField().addRouteAsync(source -> source.stream(null));

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void bFieldUnsubscribe() {
        byte[] expected= new byte[] {0x15, 0x05, 0x00};
        mag.magneticField().addRouteAsync(source -> source.stream(null)).continueWith(task -> {
            task.getResult().unsubscribe(0);
            return null;
        });

        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void bFieldData() {
        MagneticField expected= new MagneticField(Float.intBitsToFloat(0xb983a96d), Float.intBitsToFloat(0x392d362f), Float.intBitsToFloat(0x38958d9b));
        final Capture<MagneticField> actual= new Capture<>();

        mag.magneticField().addRouteAsync(source ->
                source.stream((data, env) -> ((Capture<MagneticField>) env[0]).set(data.value(MagneticField.class)))
        ).continueWith(task -> {
            task.getResult().setEnvironment(0, actual);
            return null;
        });
        sendMockResponse(new byte[] {0x15, 0x05, 0x4e, (byte) 0xf0, 0x53, 0x0a, 0x75, 0x04});

        assertEquals(expected, actual.get());
    }

    @Test
    public void bFieldComponentData() {
        float[] expected = new float[] {-0.0002511250f, 0.0001651875f, 0.0000713125f};
        final float[] actual= new float[3];

        mag.magneticField().addRouteAsync(source -> source.split()
                .index(0).stream((Subscriber) (data, env) -> ((float[]) env[0])[0] = data.value(Float.class))
                .index(1).stream((Subscriber) (data, env) -> ((float[]) env[0])[1] = data.value(Float.class))
                .index(2).stream((Subscriber) (data, env) -> ((float[]) env[0])[2] = data.value(Float.class))
        ).continueWith(task -> {
            task.getResult().setEnvironment(0, (Object) actual);
            task.getResult().setEnvironment(1, (Object) actual);
            task.getResult().setEnvironment(2, (Object) actual);
            return null;
        });
        sendMockResponse(new byte[] {0x15, 0x05, 0x4e, (byte) 0xf0, 0x53, 0x0a, 0x75, 0x04});

        assertArrayEquals(expected, actual, 0.0000003f);
    }
}
