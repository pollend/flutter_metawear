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


import 'package:flutter_metawear/DataToken.dart';
import 'package:flutter_metawear/Subscriber.dart';
import 'package:flutter_metawear/builder/RouteMulticast.dart';
import 'package:flutter_metawear/builder/RouteSplit.dart';
import 'package:flutter_metawear/builder/predicate/PulseOutput.dart';

/**
 * Similar to a {@link CodeBlock} except this interface is specifically for
 * data producers
 * @author Eric Tsai
 */
abstract class Action {
    /**
     * Writes the MetaWear commands to the board to be executed every time new token is created
     * @param token    Token representing the on-board token
     */
    void execute(DataToken token);
}


/**
 * Types of information the accounter processor can append to the data
 * @author Eric Tsai
 */
enum AccountType {
    /**
     * Append a looping counter to all data.
     * The counter's value is accessed by calling {@link Data#extra(Class)} with the <code>Long</code> type
     */
    COUNT,
    /** Extra information used to calculate actual timestamps for streamed data */
    TIME
}

/**
 * Output modes for the differentiail filter
 * @author Eric Tsai
 */
enum DifferentialOutput {
    /** Return the data as is */
    ABSOLUTE,
    /** Return the difference between the value and its reference point */
    DIFFERENCE,
    /** 1 if the difference is positive, -1 if negative */
    BINARY
}


/**
 * Supported comparison operations
 * @author Eric Tsai
 */
enum Comparison {
    /** Equal */
    EQ,
    /** Not equal */
    NEQ,
    /** Less than */
    LT,
    /** Less than or equal to */
    LTE,
    /** Greater than */
    GT,
    /** Greater than or equal to */
    GTE
}


/**
 * Operation modes for the passthrough limiter
 * @author Eric Tsai
 */
enum Passthrough {
    /** Allow all data through */
    ALL,
    /** Only allow data through if value &gt; 0 */
    CONDITIONAL,
    /** Only allow a fixed number of data samples through */
    COUNT
}


/**
 * Output modes for the threshold filter
 * @author Eric Tsai
 */
enum ThresholdOutput {
    /** Return the data as is */
    ABSOLUTE,
    /** 1 if the data exceeded the threshold, -1 if below */
    BINARY
}

/**
 * Output modes for the comparison filter, only supported by firmware v1.2.3 or higher
 * @author Eric Tsai
 */
enum ComparisonOutput {
    /** Input value is returned when the comparison is satisfied */
    ABSOLUTE,
    /** The reference value that satisfies the comparison is returned, no output if none match */
    REFERENCE,
    /** The index (0 based) of the value that satisfies the comparison is returned, n if none match */
    ZONE,
    /** 0 if comparison failed, 1 if it passed */
    PASS_FAIL
}


abstract class Filter{
}

class ThresholdFilter implements Filter {
    final ThresholdOutput output;
    final num threshold;
    final num hysteresis;

    ThresholdFilter(this.output, this.threshold, [this.hysteresis = 0]);
}

class ComparisonFilter implements Filter {
    final Comparison op;
    final ComparisonOutput comparisonOutput;
    final dynamic target;

    ComparisonFilter(this.op, this.comparisonOutput, this.target);
}

class DifferentialFilter implements Filter {
    final DifferentialOutput op;
    final num distance;

    DifferentialFilter(this.op, this.distance);
}


enum Function1 {
    /** Calculates the absolute value */
    ABS_VALUE,
    /** Calculate root sum square (vector magnitude) */
    RMS,
    /** Calculate root mean square */
    RSS,
    /** Calculate square root */
    SQRT
}

enum Function2 {
    /** Add the data */
    ADD,
    /** Multiply the data */
    MULTIPLY,
    /** Divide the data */
    DIVIDE,
    /** Calculate the remainder */
    MODULUS,
    /** Calculate exponentiation of the data */
    EXPONENT,
    /** Perform left shift */
    LEFT_SHIFT,
    /** Perform right shift */
    RIGHT_SHIFT,
    /** Subtract the data */
    SUBTRACT,
    /** Transforms the input into a constant value */
    CONSTANT
}


class FunctionBuilder {
    final dynamic handler;
    final dynamic target;

    FunctionBuilder.abs(): handler = Function1.ABS_VALUE, target = null;
    FunctionBuilder.rms(): handler = Function1.RMS, target = null;
    FunctionBuilder.rss(): handler = Function1.RSS, target = null;
    FunctionBuilder.sqrt(): handler = Function1.SQRT, target = null;

    FunctionBuilder.add(dynamic target): handler = Function2.ADD,this.target = target;
    FunctionBuilder.multiply(dynamic target): handler = Function2.MULTIPLY,this.target = target;
    FunctionBuilder.divide(dynamic target): handler = Function2.DIVIDE,this.target = target;
    FunctionBuilder.modulus(dynamic target): handler = Function2.MODULUS,this.target = target;
    FunctionBuilder.exponent(dynamic target): handler = Function2.EXPONENT,this.target = target;
    FunctionBuilder.leftShift(dynamic target): handler = Function2.LEFT_SHIFT,this.target = target;
    FunctionBuilder.rightShift(dynamic target): handler = Function2.RIGHT_SHIFT,this.target = target;
    FunctionBuilder.subtract(dynamic target): handler = Function2.SUBTRACT,this.target = target;
    FunctionBuilder.constant(dynamic target): handler = Function2.CONSTANT,this.target = target;
}


/**
 * Component in a route definition
 * @author Eric Tsai
 */
abstract class RouteComponent {

    /**
     * Splits the route directing the input data to different end points
     * @return Element for building multicast routes
     */
    RouteMulticast multicast();
    /**
     * Signals the creation of a new multicast branch
     * @return RouteComponent from the most recent multicast component
     */
    RouteComponent to();
    /**
     * Separates multi=component data into its individual values
     * @return Element for building routes for component data values
     */
    RouteSplit split();
    /**
     * Gets a specific component value from the split data value
     * @param i    Position in the split values array to return
     * @return Object representing the component value
     */
    RouteComponent index(int i);
    /**
     * Signifies the end of a split or multicast route.  Control is return to the most recent multicast or split route element
     * @return Most recent multicast or split route
     */
    RouteComponent end();

    /**
     * Assigns a user-defined name identifying the data processor.  The key can be used to modify the processor configuration,
     * read its state, and create feedback or feedforward loops with other data processors
     * @param name    Value to name the most recent data processor
     * @return Calling object
     * @see DataProcessor#edit(String, Class)
     * @see DataProcessor#state(String)
     */
    RouteComponent name(String name);
    /**
     * Streams the input data to the local device
     * @param subscriber    Subscriber to handle the received data
     * @return Calling object
     */
    RouteComponent stream(Subscriber subscriber);
    /**
     * Records the input data to the on-board logger, retrieved when a log download is started
     * @param subscriber    Subscriber to handle the received data
     * @return Calling object
     */
    RouteComponent log(Subscriber subscriber);
    /**
     * Programs the board to react in response to data being created by the most resent sensor or processor
     * @param action    On-board action to execute
     * @return Calling object
     */
    RouteComponent react(Action action);

    /**
     * Stores the input data in memory.  The currently stored value can be extracted by reading he buffer state.
     * As this buffer has no output, the route cannot continue thus the route either ends here or control is
     * passed back to the most recent multicast or splitter
     * @return Object for continuing the route
     */
    RouteComponent buffer();
    /**
     * Combines data from multiple sources into 1 packet.  The additional data you want to combine must first be
     * stored into a named buffer.
     * @param bufferNames   Named buffer components holding the extra data to combine
     * @return Object for continuing the route
     */
    RouteComponent fuse(List<String> bufferNames);

    /**
     * Counts the number of data samples that have passed through this component and outputs the current count
     * @return Object representing the output of the counter
     */
    RouteComponent count();
    /**
     * Accumulates a running sum of all data samples passing through this component and outputs the current tally
     * @return Object representing the output of the counter
     */
    RouteComponent accumulate();

    /**
     * Applies a high pass filter over the input data, available in firmware v1.3.4 and later
     * @param nSamples    Number of previous data samples to compare against
     * @return Object representing the high pass output
     */
    RouteComponent highpass(int nSamples);
    /**
     * Applies a low pass filter over the input data.  Starting in firmware v1.3.4, can be used with
     * multi-component data e.g. acceleration values.
     * @param nSamples    Number of previous data samples to compare against
     * @return Object representing the low pass output
     */
    RouteComponent lowpass(int nSamples);
    /**
     * Computes a moving average over the previous N samples.  This component will not output data
     * until the first average i.e. until N samples have been received.
     * @param nSamples    Number of samples to average over
     * @return Object representing the output of the averager
     * @deprecated Renamed to {@link #lowpass(byte) lowpass} in SDK v3.1
     */
    @deprecated
    RouteComponent average(int nSamples);
    /**
     * Stops data from leaving until at least N samples have been collected.
     * @param samples    Number of samples to collect
     * @return Object representing the output of the sample delay component
     */
    RouteComponent delay(int samples);

    /**
     * Apply a 1 input function to all of the input data
     * @param fn    Function to use
     * @return Object representing the output of the mapper
     */
    RouteComponent map(FunctionBuilder func);

//    /**
//     * Apply a 2 input function to all of the input data
//     * @param fn    Function to use
//     * @param rhs   Second input for the function
//     * @return Object representing the output of the mapper
//     */
//    RouteComponent map(Function2 fn, num rhs);
//    /**
//     * Variant of {@link #map(Function2, Number)} where the rhs value is the output of another
//     * sensor or processor
//     * @param fn          Function to apply to the input data
//     * @param dataNames   Keys identifying which sensor or processor data to feed into the mapper
//     * @return Object representing the output of the mapper
//     */
//    RouteComponent map(Function2 fn, List<String> dataNames);

    /**
     * Reduce the amount of data allowed through such that the output data rate matches the delay
     * @param period    How often to allow data through, in milliseconds (ms)
     * @return Object representing the output of the limiter
     */
    RouteComponent resample(int period);
    /**
     * Only allow data through under certain user controlled conditions
     * @param type     Passthrough operation type
     * @param value    Initial value to set the passthrough limiter to
     * @return Object representing the output of the limiter
     */
    RouteComponent limit(Passthrough type, int value);


    /**
     * Scans the input data for a pulse.  When one is detected, output a summary of the scanned data
     * @param output       Type of summary data to output
     * @param threshold    Value the sensor data must exceed for a valid pulse
     * @param samples      Minimum number of samples that must be above the threshold for a valid pulse
     * @return Object representing the output of the pulse finder
     */
    RouteComponent find(PulseOutput output, num threshold, int samples);

    /**
     * Remove data from the route that does not satisfy the comparison
     * @param op            Comparison operation to perform
     * @param references    Reference values to compare against, can be multiple values if the board
     *                      is on firmware v1.2.3 or later
     * @return Object representing the output of the comparator filter
     */
    //RouteComponent filter(Comparison op, List<num>  references);
    /**
     * Variant of the {@link #filter(Comparison, Number...)} function where the reference values are outputs
     * from other sensors or processors
     * @param op          Comparison operation to perform
     * @param dataNames   Names identifying which sensor or processor data to use as the reference value when
     *                    new values are produced
     * @return Object representing the output of the comparator filter
     */
    //RouteComponent filter(Comparison op, List<String> dataNames);
    /**
     * Variant of {@link #filter(Comparison, Number...)} where the filter can output values providing
     * additional details about the comparison.  This variant component is only supported starting with
     * firmware v1.2.5.  <b>Note that if {@link ComparisonOutput#PASS_FAIL}
     * or {@link ComparisonOutput#ZONE} is used, component will instead function as a <code>map</code>
     * component.</b>
     * @param op            Comparison operation to perform.
     * @param output        Output type the filter should produce
     * @param references    Reference values to compare against, can be multiple values if the board
     *                      is on firmware v1.2.3 or later
     * @return Object representing the output of the comparator filter
     */
//    RouteComponent filter(Comparison op, ComparisonOutput output, List<num> references);

    RouteComponent filter(Filter filter);
    /**
     * Variant of {@link #filter(Comparison, ComparisonOutput, Number...)} where reference values are outputs
     * from other sensors or processors.
     * @param op          Comparison operation to perform
     * @param output      Output type of the filter
     * @param dataNames   Names identifying which sensor or processor data to use as the reference value when
     *                    new values are produced
     * @return Object representing the output of the comparator filter
     */
//    RouteComponent filter(Comparison op, ComparisonOutput output, List<String> dataNames);
    /**
     * Remove data from the route that doesn't not cross the threshold
     * @param output       Type of output the filter will produce
     * @param threshold    Threshold boundary the data must cross
     * @return Object representing the output of the threshold filter
     */
//    RouteComponent filter(ThresholdOutput output, num threshold,[num hysteresis]);
    /**
     * Variant of {@link #filter(ThresholdOutput, Number)} with a configurable hysteresis value for data
     * that frequently oscillates around the threshold boundary
     * @param output       Type of output the filter will produce
     * @param threshold    Threshold boundary the data must cross
     * @param hysteresis   Minimum distance between the boundary and value that indicates a successful crossing
     * @return Object representing the output of the threshold filter
     */
//    RouteComponent filter(ThresholdOutput output, num threshold, num hysteresis);
    /**
     * Removes data that it is not a minimum distance away from a reference value.  The reference value is
     * continually updated to be the previous passing value
     * @param output        Type of output the filter will produce
     * @param distance      Minimum distance from the reference value
     * @return Object representing the output of the differential filter
     */
//    RouteComponent filter(DifferentialOutput output, num distance);

    /**
     * Packs multiple input values into 1 BTLE packet.  Used to reduce the number of packets broadcasted over the link.
     * @param count    Number of input values to pack
     * @return Object representing the output of the packer
     */
    RouteComponent pack(int count);

    /**
     * Variant of {@link #account(AccountType)} that defaults to recalculating timestamps
     * @return Object representing the accounter output
     */
    RouteComponent account([AccountType type]);
    /**
     * Add additional information to the payload to assist in checking if streamed data is lost
     * @param type      Type of information to append to the data<
     * @return Object representing the accounter output
     */
//    RouteComponent account(AccountType type);
}
