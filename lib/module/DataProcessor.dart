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


import 'package:flutter_metawear/ForcedDataProducer.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';
import 'package:flutter_metawear/builder/filter/Comparison.dart';
import 'package:flutter_metawear/builder/filter/Passthrough.dart';

/**
 * Common base class for all data processor editors
 * @author Eric Tsai
 */
abstract class Editor { }

/**
 * Edits a fixed value comparator filter
 * @author Eric Tsai
 * @see RouteComponent#filter(Comparison, Number...)
 * @see RouteComponent#filter(Comparison, ComparisonOutput, Number...)
 */
abstract class ComparatorEditor extends Editor {
    /**
     * Modifies the references values and comparison operation
     * @param op            New comparison operation
     * @param references    New reference values, can be multiple values if the board is running
     *                      firmware v1.2.3 or later
     */
    void modify(Comparison op, List<num> references);
}

/**
 * Edits a threshold filter
 * @author Eric Tsai
 * @see RouteComponent#filter(ThresholdOutput, Number)
 * @see RouteComponent#filter(ThresholdOutput, Number, Number)
 */
abstract class ThresholdEditor extends Editor {
    /**
     * Modifies the threshold and hysteresis values
     * @param threshold     New threshold value
     * @param hysteresis    New hysteresis value
     */
    void modify(num threshold, num hysteresis);
}

/**
 * Edits a differential filter
 * @author Eric Tsai
 * @see RouteComponent#filter(DifferentialOutput, Number)
 */
abstract class DifferentialEditor extends Editor {
    /**
     * Modifies the minimum distance from the reference value
     * @param distance    New minimum distance value
     */
    void modify(num distance);
}

/**
 * Edits a high or low pass processor
 * @author Eric Tsai
 * @see RouteComponent#lowpass(byte)
 * @see RouteComponent#highpass(byte)
 */
abstract class AverageEditor extends Editor {
    /**
     * Change how many samples are used in the average calculation
     * @param samples    New sample size
     */
    void modify(int samples);

    /**
     * Reset the running average
     */
    void reset();
}
/**
 * Edits a data processor created with the fixed value map construct
 * @author Eric Tsai
 * @see RouteComponent#map(Function2, Number)
 */
abstract class MapEditor extends Editor {
    /**
     * Modifies the right hand value used in the computation
     * @param rhs    New right hand value
     */
    void modifyRhs(num rhs);
}
/**
 * Edits an accumulator
 * @author Eric Tsai
 * @see RouteComponent#accumulate()
 */
abstract class AccumulatorEditor extends Editor {
    /**
     * Reset the running sum
     */
    void reset();

    /**
     * Overwrite the accumulated sum with a new value
     * @param value    New accumulated sum
     */
    void set(num value);
}

/**
 * Edits a counter
 * @author Eric Tsai
 * @see RouteComponent#accumulate()
 */
abstract class CounterEditor extends Editor {
    /**
     * Reset the internal counter
     */
    void reset();

    /**
     * Overwrite the internal counter with a new value
     * @param value    New count value
     */
    void set(int value);
}

/**
 * Edits a time limiter
 * @author Eric Tsai
 * @see RouteComponent#limit(int)
 */
abstract class TimeEditor extends Editor {
    /**
     * Change how often to allow data through
     * @param period    New sampling delay
     */
    void modify(int period);
}
/**
 * Edits a passthrough limiter
 * @author Eric Tsai
 * @see RouteComponent#limit(Passthrough, short)
 */
abstract class PassthroughEditor extends Editor {
    /**
     * Set the internal value
     * @param value    New internal value
     */
    void set(int value);

    /**
     * Changes the passthrough type and initial value
     * @param type     New passthrough type to use
     * @param value    Initial value of the modified filter
     */
    void modify(Passthrough type, int value);
}
/**
 * Edits a pulse finder
 * @author Eric Tsai
 * @see RouteComponent#find(PulseOutput, Number, short)
 */
abstract class PulseEditor extends Editor {
    /**
     * Change the criteria that classifies a pulse
     * @param threshold    New boundary the data must exceed
     * @param samples      New minimum data sample size
     */
    void modify(num threshold, int samples);
}
/**
 * Edits a data packer
 * @author Eric Tsai
 * @see RouteComponent#pack(byte)
 */
abstract class PackerEditor extends Editor {
    /**
     * Clears buffer of accumulated inputs
     */
    void clear();
}

/**
 * Firmware feature that manipulates data on-board
 * @author Eric Tsai
 */
abstract class DataProcessor extends Module {
    /**
     * Edits a data processor
     * @param name              Processor name to look up, set by {@link RouteComponent#name(String)}
     * @param editorClass       Editor class to modify the processor with
     * @param <T>               Runtime type the return value is casted as
     * @return Editor object to modify the processor
     */
    T edit<T extends Editor>(String name);

    /**
     * Gets a ForcedDataProducer for the processor's internal state
     * @param name    Processor name to look up, set by {@link RouteComponent#name(String)}
     * @return Object representing the processor state, null if the processor does not have a readable state
     */
    ForcedDataProducer state(String name);


}
