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


/**
 * Created by etsai on 9/4/16.
 */
abstract class FloatVectorData extends DataTypeBase {

    FloatVectorData(Constant.Module module, byte register, DataAttributes attributes) {
        super(module, register, attributes);
    }

    FloatVectorData(DataTypeBase input, Constant.Module module, byte register, byte id, DataAttributes attributes) {
        super(input, module, register, id, attributes);
    }

    @Override
    public Number convertToFirmwareUnits(MetaWearBoardPrivate mwPrivate, Number value) {
        return value.floatValue() * scale(mwPrivate);
    }

    @Override
    Pair<? extends DataTypeBase, ? extends DataTypeBase> dataProcessorTransform(DataProcessorConfig config, DataProcessorImpl dpModule) {
        switch(config.id) {
            case DataProcessorConfig.Combiner.ID: {
                DataAttributes attributes= new DataAttributes(new byte[] {this.attributes.sizes[0]}, (byte) 1, (byte) 0, false);
                return new Pair<>(new UFloatData(this, DATA_PROCESSOR, DataProcessorImpl.NOTIFY, attributes), null);
            }
        }

        return super.dataProcessorTransform(config, dpModule);
    }
}
