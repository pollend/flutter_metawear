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

import 'package:flutter_metawear/CodeBlock.dart';
import 'package:flutter_metawear/MetaWearBoard.dart';


/**
 * A task comprising of MetaWear commands programmed to run on-board at a certain times
 * @author Eric Tsai
 */
abstract class ScheduledTask {
    /**
     * Start task execution
     */
    void start();

    /**
     * Stop task execution
     */
    void stop();

    /**
     * Checks if this object represents an active task
     * @return True if task is still scheduled on-board
     */
    bool isActive();

    /**
     * Get the numerical id of this task
     * @return Task ID
     */
    int id();

    /**
     * Removes this task from the board
     */
    void remove();
}

/**
 * On-board scheduler for executing MetaWear commands in the future
 * @author Eric Tsai
 */
abstract class Timer extends Module {

    /**
     * Schedule a task to be indefinitely executed on-board at fixed intervals
     * @param period    How often to execute the task, in milliseconds
     * @param delay     True if first execution should be delayed by one {@code delay}
     * @param mwCode    MetaWear commands composing the task
     * @return Task holding the result of the scheduled request
     * @see ScheduledTask
     */
    Future<ScheduledTask> scheduleAsync(int period, bool delay, CodeBlock mwCode);

    /**
     * Schedule a task to be executed on-board at fixed intervals for a specific number of repetitions
     * @param period         How often to execute the task, in milliseconds
     * @param repetitions    How many times to execute the task
     * @param delay          True if first execution should be delayed by one {@code delay}
     * @param mwCode         MetaWear commands composing the task
     * @return Task holding the result of the scheduled task
     * @see ScheduledTask
     */
    Future<ScheduledTask> scheduleAsyncRepeated(int period, int repetitions, bool delay, CodeBlock mwCode);
    /**
     * Find the {@link ScheduledTask} object corresponding to the given id
     * @param id    Task id to lookup
     * @return Schedule task matching the id, null if no matches
     */
    ScheduledTask lookupScheduledTask(int id);
}
