
import 'dart:typed_data';

import 'package:flutter_metawear/IllegalRouteOperationException.dart';
import 'package:flutter_metawear/builder/RouteComponent.dart';
import 'package:flutter_metawear/builder/predicate/PulseOutput.dart';
import 'package:flutter_metawear/impl/DataAttributes.dart';
import 'package:flutter_metawear/impl/DataProcessorImpl.dart';
import 'package:flutter_metawear/impl/RouteComponentImpl.dart';
import 'package:flutter_metawear/impl/Version.dart';

import 'package:sprintf/sprintf.dart';


/**
 * Created by eric on 8/27/17.
 */

class Threshold extends DataProcessorConfig {
    static const int ID = 0xd;

    final int input;
    final bool isSigned;
    final ThresholdOutput mode;
    final int boundary;
    final int hysteresis;

    Threshold(this.input, this.isSigned, this.mode, this.boundary,
        this.hysteresis) : super(ID);


    Threshold.config(Uint8List cfg):
            input = ((cfg[1] & 0x3) + 1),
            isSigned = (cfg[1] & 0x4) == 0x4,
            mode = ThresholdOutput.values[(cfg[1] >> 3) & 0x7],
            boundary = ByteData.view(cfg.buffer).getUint32(2, Endian.little),
            hysteresis = ByteData.view(cfg.buffer).getUint16(6, Endian.little),
            super(cfg[0]);


    @override
    String createUri(bool state, int procId) {
        return sprintf("threshold?id=%d", procId);
    }

    @override
    Uint8List build() {
        final data = Uint8List(8);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, ID);
        buffer.setUint8(offset += 1,((input - 1) & 0x3 | (isSigned ? 0x4 : 0) | (mode.index << 3)));
        buffer.setInt32(offset += 4, boundary, Endian.little);
        buffer.setInt16(offset += 2, hysteresis, Endian.little);
        return data;
    }

}

class PassthroughConfig extends DataProcessorConfig {
    static const int ID = 0x1;

    final Passthrough type;
    final int value;

    PassthroughConfig.config(Uint8List config):
            type = Passthrough.values[config[1] & 0x7],
            value = ByteData.view(config.buffer).getUint16(2, Endian.little),
            super(config[0]);

    PassthroughConfig(this.type, this.value) : super(ID);

    @override
    Uint8List build() {
        final data = Uint8List(4);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, ID);
        buffer.setUint8(offset += 1, (type.index & 0x7));
        buffer.setInt16(offset += 2, value, Endian.little);
    }

    @override
    String createUri(bool state, int procId) =>
        sprintf("passthrough%s?id=%d", [state == null ? "-state" : "", procId]);

}


class Accumulator extends DataProcessorConfig {
    static const int ID = 0x2;

    final bool counter;
    final int output;
    final int input;

    Accumulator(this.counter, this.output, this.input) : super(ID);

    Accumulator.config(Uint8List config):
            counter = (config[1] & 0x10) == 0x10,
            output = ((config[1] & 0x3) + 1),
            input = (((config[1] >> 2) & 0x3) + 1),
            super(config[0]);


    @override
    Uint8List build() => Uint8List.fromList([ID, (((output - 1) & 0x3) | (((input - 1) & 0x3) << 2) | (counter ? 0x10 : 0))]);

    @override
    String createUri(bool state, int procId) {
        return sprintf("%s%s?id=%d",
            [counter ? "count" : "accumulate", state ? "-state" : "", procId]);
    }
}

class Average extends DataProcessorConfig {
    static const int ID = 0x3;

    final int output;
    final int input;
    final int samples;
    int nInputs;
    bool hpf, supportsHpf;

    Average(DataAttributes attributes, this.samples, this.hpf, this.supportsHpf):
            this.output = attributes.length(),
            this.input = attributes.length(),
            this.nInputs = attributes.sizes.length,
            super(ID);


    Average.config(Uint8List config):
            output = ((config[1] & 0x3) + 1),
            input = (((config[1] >> 2) & 0x3) + 1),
            samples = (config[2]),
            nInputs = config.length == 4 ? config[3] : 0,
            hpf = config.length == 4 ? (config[1] >> 5) == 1 : 0,
            supportsHpf = config.length == 4,
            super(config[0]);

    @override
    Uint8List build() {
        final data = Uint8List(supportsHpf ? 4 : 3);
        final buffer = ByteData.view(data.buffer);

        int offset = 0;
        buffer.setUint8(offset, ID);
        buffer.setUint8(offset += 1,
            ((((output - 1) & 0x3) | (((input - 1) & 0x3) << 2)) | ((supportsHpf
                ? (hpf ? 1 : 0)
                : 0) << 5)));
        buffer.setUint8(offset += 1, samples);
        if (supportsHpf)
            buffer.setUint8(offset += 1, (nInputs - 1));
        return data;
    }

    @override
    String createUri(bool state, int procId) =>
        sprintf("%s?id=%d", [hpf ? "high-pass" : "low-pass", procId
        ]);

}

abstract class ComparisonConfig extends  DataProcessorConfig {
    static const int ID = 0x6;

    ComparisonConfig(int id) : super(id);

    @override
    String createUri(bool state, int procId) => sprintf("comparison?id=%d", procId);

}

class MultiValueComparison extends ComparisonConfig {
    static void fillReferences(ByteData buffer, int length,
        List<num> references) {
        int offset = 0;
        switch (length) {
            case 1:
                for (num it in references) {
                    buffer.setUint8(offset, it);
                    offset += 1;
                }
                break;
            case 2:
                for (num it in references) {
                    buffer.setInt16(offset, it, Endian.little);
                    offset += 2;
                }
                break;
            case 4:
                for (num it in references) {
                    buffer.setInt32(offset, it, Endian.little);
                    offset += 4;
                }
                break;
        }
    }

    static List<num> extractReferences(ByteData buffer, int length) {
        List<num> references = null;
        int remaining = buffer.lengthInBytes;

        switch (length) {
            case 1:
                references = List<num>(remaining);
                for (int i = 0; i < references.length; i++) {
                    references[i] = buffer.getUint8(i);
                }
                break;
            case 2:
                references = List<num>((remaining / 2).round());
                for (int i = 0; i < references.length; i++) {
                    references[i] = buffer.getUint16(i * 2, Endian.little);
                }
                break;
            case 4:
                references = List<num>((remaining / 4).round());
                for (int i = 0; i < references.length; i++) {
                    references[i] = buffer.getUint32(i * 4, Endian.little);
                }
                break;
        }

        return references;
    }

    int input;
    final List<num> references;
    final Comparison op;
    final ComparisonOutput mode;
    final bool isSigned;

    MultiValueComparison(this.isSigned, this.input, this.op, this.mode,
        this.references) : super(ComparisonConfig.ID);


    MultiValueComparison.config(Uint8List config)
        :
            this.isSigned = (config[1] & 0x1) == 0x1,
            this.input = (((config[1] >> 1) & 0x3) + 1),
            this.op = Comparison.values[(config[1] >> 3) & 0x7],
            this.mode = ComparisonOutput.values[(config[1] >> 6) & 0x3],
            this.references = extractReferences(ByteData.view(config.buffer, 2),
                (((config[1] >> 1) & 0x3) + 1)),
            super(config[0]);


    @override
    Uint8List build() {
        final data = Uint8List(2 + references.length * input);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, 0x6);
        buffer.setUint8(offset += 1,
            ((isSigned ? 1 : 0) | ((input - 1) << 1) | (op.index << 3) | (mode
                .index << 6)));
        fillReferences(ByteData.view(data.buffer, offset), input, references);

        return data;
    }
}


class SingleValueComparison extends ComparisonConfig {
    final bool isSigned;
    final Comparison op;
    final int reference;

    SingleValueComparison(this.isSigned, this.op, this.reference)
        : super(ComparisonConfig.ID);

    SingleValueComparison.config(Uint8List config):
            isSigned = config[1] == 0x1,
            op = Comparison.values[config[2]],
            reference = ByteData.view(config.buffer).getUint8(4),
            super(config[0]);


    @override
    Uint8List build() {
        final data = Uint8List(8);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, ComparisonConfig.ID);
        buffer.setUint8(offset += 1, isSigned ? 1 : 0);
        buffer.setUint8(offset += 1, op.index);
        buffer.setUint8(offset += 1, 0);
        buffer.setInt32(offset += 4, reference);
    }
}

class Combiner extends DataProcessorConfig {
    static const int ID = 0x7;

    final int output;
    final int input;
    final int nInputs;
    final bool isSigned;
    final bool rss;

    Combiner(DataAttributes attributes, this.rss):
            this.output = attributes.sizes[0],
            this.input = attributes.sizes[0],
            this.nInputs = attributes.sizes.length,
            this.isSigned = attributes.signed,
            super(ID);

    Combiner.config(Uint8List config):
            output = ((config[1] & 0x3) + 1),
            input = (((config[1] >> 2) & 0x3) + 1),
            nInputs = (((config[1] >> 4) & 0x3) + 1),
            isSigned = (config[1] & 0x80) == 0x80,
            rss = config[2] == 1,
            super(config[0]);


    @override
    Uint8List build() {
        return new Uint8List.fromList([
            ID,
            (((output - 1) & 0x3) | (((input - 1) & 0x3) << 2) | (((nInputs -
                1) & 0x3) << 4) | (isSigned ? 0x80 : 0)),
            (rss ? 1 : 0)
        ]);
    }

    @override
    String createUri(bool state, int procId) {
        return sprintf("%s?id=%d", [rss ? "rss" : "rms", procId]);
    }
}

class Time extends DataProcessorConfig {
    static const int ID = 0x8;

    final int input;
    final int type;
    final int period;

    Time(this.input, this.type, this.period) : super(ID);

    Time.config(Uint8List config)
        :
            period = ByteData.view(config.buffer).getUint32(2, Endian.little),
            input = ((config[1] & 0x7) + 1),
            type = ((config[1] >> 3) & 0x7),
            super(config[0]);


    @override
    Uint8List build() {
        final data = Uint8List(6);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, ID);
        buffer.setUint8(offset += 1, ((input - 1) & 0x7 | (type << 3)));
        buffer.setInt32(offset += 4, period);
    }

    @override
    String createUri(bool state, int procId) {
        return sprintf("time?id=%d", [procId]);
    }
}


enum Operation {
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
    /** Calculate square root */
    SQRT,
    /** Perform left shift */
    LEFT_SHIFT,
    /** Perform right shift */
    RIGHT_SHIFT,
    /** Subtract the data */
    SUBTRACT,
    /** Calculates the absolute value */
    ABS_VALUE,
    /** Transforms the input into a constant value */
    CONSTANT
}

class Maths extends DataProcessorConfig {
    static const int ID = 0x9;
    
    int output;
    final int input;
    int nInputs;
    final bool isSigned;
    bool multiChnlMath;
    final Operation op;
    final int rhs;

    Maths(DataAttributes attributes, this.multiChnlMath, this.op, this.rhs)
        :
            this.output = -1,
            this.input = attributes.sizes[0],
            this.nInputs = attributes.sizes.length,
            this.isSigned = attributes.signed,
            super(ID);

    Maths.config(this.multiChnlMath, Uint8List config)
        :
            output = ((config[1] & 0x3) + 1),
            input = (((config[1] >> 2) & 0x3) + 1),
            isSigned = (config[1] & 0x10) == 0x10,
            op = Operation.values[config[2] - 1],
            rhs = ByteData.view(config.buffer).getInt32(3, Endian.little),
            nInputs = multiChnlMath ? (config[7] + 1) : 0,
            super(config[0]);


    @override
    Uint8List build() {
        if (output == -1) {
            throw Exception("Output length cannot be negative");
        }

        final data = Uint8List(multiChnlMath ? 8 : 7);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setUint8(offset, ID);
        buffer.setUint8(offset += 1,
            ((output - 1) & 0x3 | ((input - 1) << 2) | (isSigned ? 0x10 : 0)));
        buffer.setUint8(offset += 1, op.index);
        buffer.setInt32(offset += 4, rhs);
        if (multiChnlMath)
            buffer.setInt8(offset += 1, nInputs - 1);
        return data;
    }

    @override
    String createUri(bool state, int procId) {
        return sprintf("math?id=%d", [procId]);
    }
}

class Delay extends DataProcessorConfig {
    static const int ID = 0xa;

    final bool expanded;
    final int input;
    final int samples;

    Delay(this.expanded, this.input, this.samples) : super(ID);

    Delay.config(this.expanded, Uint8List config)
        :
            input = ((config[1] & (expanded ? 0xf : 0x3)) + 1),
            samples = config[2],
            super(config[0]);

    @override
    Uint8List build() =>
        Uint8List.fromList(
            [ID, ((input - 1) & (expanded ? 0xf : 0x3)), samples]);

    @override
    String createUri(bool state, int procId) => sprintf("delay?id=%d", procId);
}

class Pulse extends DataProcessorConfig {
    static const int ID = 0xb;

    final int input;
    final int threshold;
    final int samples;
    final PulseOutput mode;

    Pulse(this.input, this.threshold, this.samples, this.mode) :super(ID);


    Pulse.config(Uint8List config)
        :
            input = (config[2] + 1),
            threshold = ByteData.view(config.buffer).getInt32(4, Endian.little),
            samples = ByteData.view(config.buffer).getInt16(8, Endian.little),
            mode = PulseOutput.values[config[4]],
            super(config[0]);


    Uint8List build() {
        final data = Uint8List(10);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setInt8(offset, ID);
        buffer.setInt8(offset += 1, 0);
        buffer.setInt8(offset += 1, mode.index);
        buffer.setInt8(offset += 1, threshold);
        buffer.setInt8(offset += 1, samples);
        return data;
    }

    @override
    String createUri(bool state, int procId) {
        return sprintf("pulse?id=%d", [procId]);
    }
}

class Differential extends DataProcessorConfig {
    static const int ID = 0xc;

    final int input;
    final bool isSigned;
    final DifferentialOutput mode;
    final int differential;

    Differential(this.input, this.isSigned, this.mode, this.differential)
        :super(ID);


    Differential.config(Uint8List config)
        :
            input = ((config[1] & 0x3) + 1),
            isSigned = (config[1] & 0x4) == 0x4,
            mode = DifferentialOutput.values[(config[1] >> 3) & 0x7],
            differential = ByteData.view(config.buffer).getInt32(1),
            super(config[0]);


    @override
    Uint8List build() {
        final data = Uint8List(10);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setInt8(offset, ID);
        buffer.setInt8(offset += 1,
            (((input - 1) & 0x3) | (isSigned ? 0x4 : 0) | (mode.index << 3)));
        buffer.setInt32(offset += 4, differential, Endian.little);
        return data;
    }

    @override
    String createUri(bool state, int procId) {
        return sprintf("differential?id=%d", [procId]);
    }
}



class Buffer extends DataProcessorConfig {
    static const int ID = 0xf;

    final int input;

    Buffer(this.input) :super(ID);


    Buffer.config(Uint8List config):
            input = ((config[1] & 0x1f) + 1),
            super(config[0]);

    @override
    Uint8List build() => Uint8List.fromList([ID, ((input - 1) & 0x1f)]);

    @override
    String createUri(bool state, int procId) =>
        sprintf("buffer%s?id=%d", [state ? "-state" : "", procId]);
}

class Packer extends DataProcessorConfig {
    static const int ID = 0x10;

    final int input;
    final int count;

    Packer(this.input, this.count) : super(ID);


    Packer.config(Uint8List config):
            input = ((config[1] & 0x1f) + 1),
            count = ((config[2] & 0x1f) + 1),
            super(config[0]);


    @override
    Uint8List build() =>
        Uint8List.fromList([ID, ((input - 1) & 0x1f), ((count - 1) & 0x1f)]);

    @override
    String createUri(bool state, int procId) =>
        sprintf("packer?id=%d", [procId]);
}


class Accounter extends DataProcessorConfig {
    static const int ID = 0x11;

    final int length;
    final AccountType type;

    Accounter(this.length, this.type) : super(ID);


    Accounter.confg(Uint8List config)
        :
            this.length = (((config[1] >> 4) & 0x3) + 1),
            this.type = AccountType.values[config[1] & 0xf],
            super(config[0]);


    @override
    Uint8List build() =>
        Uint8List.fromList([ID, (type.index | ((length - 1) << 4)), 0x3]);


    @override
    String createUri(bool state, int procId) =>
        sprintf("account?id=%d", [procId]);
}

class Fuser extends DataProcessorConfig {
    static const int ID = 0x1b;

    final List<String> names;
    final Uint8List filterIds;

    Fuser(this.names)
        :
            this.filterIds = Uint8List(names.length),
            super(ID);


    Fuser.config(Uint8List config)
        :
            this.names = null,
            this.filterIds = Uint8List(config[1] & 0x1f),
            super(config[0]){
        this.filterIds.setAll(0, config.skip(2));
    }


    void syncFilterIds(DataProcessorImpl dpModule) {
        int i = 0;
        for (String it in names) {
            if (!dpModule.nameToIdMapping.containsKey(it)) {
                throw new IllegalRouteOperationException(
                    "No processor named \"" + it + "\" found");
            }

            int id = dpModule.nameToIdMapping[it];
            Processor value = dpModule.activeProcessors[id];
            if (!(value.editor.configObj is Buffer)) {
                throw new IllegalRouteOperationException(
                    "Can only use buffer processors as inputs to the fuser");
            }

            filterIds[i] = id;
            i++;
        }
    }

    @override
    Uint8List build() {
        final data = Uint8List(2 + filterIds.length);
        final buffer = ByteData.view(data.buffer);
        int offset = 0;
        buffer.setInt8(offset, ID);
        buffer.setInt8(offset += 1, filterIds.length);
        for (int filterId in filterIds)
            buffer.setInt8(offset += 1, filterId);
        return data;
    }

    @override
    String createUri(bool state, int procId) =>
        sprintf("fuser?id=%d", [procId]);

}

abstract class DataProcessorConfig {
    static DataProcessorConfig from(Version firmware, int revision, Uint8List config) {
        switch(config[0]) {
            case PassthroughConfig.ID:
                return PassthroughConfig.config(config);
            case Accumulator.ID:
                return Accumulator.config(config);
            case Average.ID:
                return Average.config(config);
            case ComparisonConfig.ID:
                return firmware.compareTo(RouteComponentImpl.MULTI_COMPARISON_MIN_FIRMWARE) >= 0 ?
                        new MultiValueComparison.config(config) : new SingleValueComparison.config(config);
            case Combiner.ID:
                return Combiner.config(config);
            case Time.ID:
                return Time.config(config);
            case Maths.ID:
                return new Maths.config(firmware.compareTo(RouteComponentImpl.MULTI_CHANNEL_MATH) >= 0, config);
            case Delay.ID:
                return new Delay.config(revision >= DataProcessorImpl.EXPANDED_DELAY, config);
            case Pulse.ID:
                return Pulse.config(config);
            case Differential.ID:
                return Differential.config(config);
            case Threshold.ID:
                return Threshold.config(config);
            case Buffer.ID:
                return Buffer.config(config);
            case Packer.ID:
                return Packer.config(config);
            case Accounter.ID:
                return Accounter.confg(config);
            case Fuser.ID:
                return Fuser.config(config);
            default:
                break;
        }
        throw Exception("Unrecognized config id: $config[0]");
    }

    final int id;

    DataProcessorConfig(this.id);

    Uint8List build();
    String createUri(bool state, int procId);

}