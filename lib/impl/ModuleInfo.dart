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


import 'dart:typed_data';

import 'package:flutter_metawear/impl/Util.dart';

/**
 * Created by etsai on 8/31/16.
 */
class ModuleInfo{
//    private static final long serialVersionUID = -8120230312302254264L;

    final int id, implementation, revision;
    final Uint8List extra;

    ModuleInfo._(this.id,this.implementation,this.revision,this.extra);

    factory ModuleInfo(Uint8List response){
        int id = response[0];
        int implementation;
        int revision;
        Uint8List extra;

        if (response.length > 2) {
            implementation = response[2];
            revision = response[3];
        } else {
            implementation= 0xff;
            revision= 0xff;
        }
        if (response.length > 4) {
            extra = Uint8List(response.length - 4);
            extra.setAll(0, response.skip(4));
        } else {
            extra= Uint8List(0);
        }

        return ModuleInfo._(id, implementation, revision, extra);
    }


    bool present() {
        return implementation != 0xff && revision != 0xff;
    }

    Map<String,dynamic> toJSON() {
        if (!present()) {
            return Map();
        }

        Map<String,dynamic> attributes = Map();
        attributes["implementation"] =  implementation;
        attributes["revision"] =  revision;

        if (extra.length > 0) {
            attributes["extra"] =  Util.arrayToHexString(extra);
        }

        return attributes;
    }
}
