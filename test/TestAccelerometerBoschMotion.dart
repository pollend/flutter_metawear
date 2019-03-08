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

import com.mbientlab.metawear.data.Sign;
import com.mbientlab.metawear.module.AccelerometerBma255;
import com.mbientlab.metawear.module.AccelerometerBmi160;
import com.mbientlab.metawear.module.AccelerometerBosch;
import com.mbientlab.metawear.module.AccelerometerBosch.AnyMotionDataProducer;
import com.mbientlab.metawear.module.AccelerometerBosch.NoMotionDataProducer;
import com.mbientlab.metawear.module.AccelerometerBosch.SlowMotionDataProducer;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

import java.util.ArrayList;
import java.util.Collection;

import bolts.Capture;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;

/**
 * Created by etsai on 12/19/16.
 */
@RunWith(Parameterized.class)
public class TestAccelerometerBoschMotion extends UnitTestBase {
    @Parameters(name = "board: {0}")
    public static Collection<Object[]> boardsParams() {
        ArrayList<Object[]> parameters= new ArrayList<>();
        parameters.add(new Object[] {AccelerometerBma255.class});
        parameters.add(new Object[] {AccelerometerBmi160.class});

        return parameters;
    }

    private AccelerometerBosch boschAcc;

    @Parameter
    public Class<? extends AccelerometerBosch> accelClass;

    @Before
    public void setup() throws Exception {
        junitPlatform.boardInfo = new MetaWearBoardInfo(accelClass);
        connectToBoard();

        boschAcc = mwBoard.getModule(AccelerometerBosch.class);
    }

    @Test
    public void startNoMotion() {
        byte[] expected = accelClass.equals(AccelerometerBmi160.class) ?
                new byte[] {0x03, 0x09, 0x38, 0x00} :
                new byte[] {0x03, 0x09, 0x78, 0x00};

        boschAcc.motion(NoMotionDataProducer.class).start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void stopNoMotion() {
        byte[] expected = accelClass.equals(AccelerometerBmi160.class) ?
                new byte[] {0x03, 0x09, 0x00, 0x38} :
                new byte[] {0x03, 0x09, 0x00, 0x78};

        boschAcc.motion(NoMotionDataProducer.class).stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void configureNoMotion() {
        byte[] expected = accelClass.equals(AccelerometerBmi160.class) ?
                new byte[] {0x03, 0x0a, 0x18, 0x14, 0x7f, 0x15} :
                new byte[] {0x03, 0x0a, 0x24, 0x14, 0x7f};

        boschAcc.motion(NoMotionDataProducer.class).configure()
                .duration(10000)
                .threshold(0.5f)
                .commit();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void noMotionData() {
        final byte expected = 0x4;
        final Capture<Byte> actual = new Capture<>();

        boschAcc.motion(NoMotionDataProducer.class).addRouteAsync(source -> source.stream((data, env) -> actual.set(data.bytes()[0])));
        sendMockResponse(new byte[] {0x03, 0x0b, 0x04});

        assertEquals(expected, actual.get().byteValue());
    }

    @Test
    public void startSlowMotion() {
        byte[] expected = new byte[] {0x03, 0x09, 0x38, 0x00};

        boschAcc.motion(SlowMotionDataProducer.class).start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void stopSlowMotion() {
        byte[] expected = new byte[] {0x03, 0x09, 0x00, 0x38};

        boschAcc.motion(SlowMotionDataProducer.class).stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void configureSlowMotion() {
        byte[] expected = accelClass.equals(AccelerometerBmi160.class) ?
                new byte[] {0x03, 0x0a, 0x10, 0x14, (byte) 0xc0, 0x14} :
                new byte[] {0x03, 0x0a, 0x10, 0x14, (byte) 0xc0};

        boschAcc.configure()
                .range(4f)
                .commit();
        boschAcc.motion(SlowMotionDataProducer.class).configure()
                .threshold(1.5f)
                .count((byte) 5)
                .commit();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void slowMotionData() {
        final byte expected = 0x4;
        final Capture<Byte> actual = new Capture<>();

        boschAcc.motion(SlowMotionDataProducer.class).addRouteAsync(source -> source.stream((data, env) -> actual.set(data.bytes()[0])));
        sendMockResponse(new byte[] {0x03, 0x0b, 0x04});

        assertEquals(expected, actual.get().byteValue());
    }

    @Test
    public void startAnyMotion() {
        byte[] expected = new byte[] {0x03, 0x09, 0x07, 0x00};

        boschAcc.motion(AnyMotionDataProducer.class).start();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void stopAnyMotion() {
        byte[] expected = new byte[] {0x03, 0x09, 0x00, 0x07};

        boschAcc.motion(AnyMotionDataProducer.class).stop();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void configureAnyMotion() {
        byte[] expected = accelClass.equals(AccelerometerBmi160.class) ?
                new byte[] {0x03, 0x0a, 0x01, 0x2f, 0x14, 0x14} :
                new byte[] {0x03, 0x0a, 0x01, 0x2f, 0x14};

        boschAcc.configure()
                .range(8f)
                .commit();
        boschAcc.motion(AnyMotionDataProducer.class).configure()
                .threshold(0.75f)
                .count((byte) 10)
                .commit();
        assertArrayEquals(expected, junitPlatform.getLastCommand());
    }

    @Test
    public void anyMotionData() {
        final AccelerometerBosch.AnyMotion[] expected = new AccelerometerBosch.AnyMotion[] {
                new AccelerometerBosch.AnyMotion(Sign.POSITIVE, false, false, true),
                new AccelerometerBosch.AnyMotion(Sign.NEGATIVE, false, false, true),
                new AccelerometerBosch.AnyMotion(Sign.NEGATIVE, false, true, false),
                new AccelerometerBosch.AnyMotion(Sign.POSITIVE, false, true, false),
                new AccelerometerBosch.AnyMotion(Sign.POSITIVE, true, false, false),
                new AccelerometerBosch.AnyMotion(Sign.NEGATIVE, true, false, false)
        };
        final byte[][] responses = new byte[][] {
                {0x03, 0x0b, 0x22},
                {0x03, 0x0b, 0x62},
                {0x03, 0x0b, 0x52},
                {0x03, 0x0b, 0x12},
                {0x03, 0x0b, 0x0a},
                {0x03, 0x0b, 0x4a}
        };
        final Capture<AccelerometerBosch.AnyMotion[]> actual = new Capture<>();

        actual.set(new AccelerometerBosch.AnyMotion[6]);
        boschAcc.motion(AnyMotionDataProducer.class).addRouteAsync(source -> source.stream(new Subscriber() {
            int i = 0;
            @Override
            public void apply(Data data, Object... env) {
                actual.get()[i] = data.value(AccelerometerBosch.AnyMotion.class);
                i++;
            }
        }));
        for(byte[] it: responses) {
            sendMockResponse(it);
        }

        assertArrayEquals(expected, actual.get());
    }

}
