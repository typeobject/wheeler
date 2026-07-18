/// Interns bounded immutable record and finite-variant values.
module examples.compiler.aggregate_interpreter;
import examples.compiler.opcodes;
classical class AggregateInterpreter {
    public record AggregateAllocation(
        long handle,
        long aggregateCount,
        long fieldCursor
    ) {}

    public AggregateAllocation internAggregate(
        words aggregateTypes,
        words aggregateTags,
        words aggregateStarts,
        words aggregateCounts,
        words aggregateFields,
        words locals,
        long localBase,
        long typeCode,
        long tag,
        long fieldBase,
        long fieldCount,
        long aggregateCount,
        long fieldCursor
    ) {
        long aggregate = 0;
        while (aggregate < aggregateCount)
            limit INTERPRETER_AGGREGATE_COUNT {
            boolean equal = aggregateTypes[aggregate] == typeCode;
            if (aggregateTags[aggregate] == tag) {
            } else {
                equal = false;
            }
            if (aggregateCounts[aggregate] == fieldCount) {
            } else {
                equal = false;
            }
            long field = 0;
            while (field < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
                if (aggregateFields[aggregateStarts[aggregate] + field]
                        == locals[localBase + fieldBase + field]) {
                } else {
                    equal = false;
                }
                field += 1;
            }
            if (equal) {
                return new AggregateAllocation(
                    aggregate + 1, aggregateCount, fieldCursor);
            }
            aggregate += 1;
        }
        if (aggregateCount < INTERPRETER_AGGREGATE_COUNT) {
        } else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        if (fieldCursor + fieldCount < INTERPRETER_AGGREGATE_FIELDS + 1) {
        } else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        set(aggregateTypes, aggregateCount, typeCode);
        set(aggregateTags, aggregateCount, tag);
        set(aggregateStarts, aggregateCount, fieldCursor);
        set(aggregateCounts, aggregateCount, fieldCount);
        long copy = 0;
        while (copy < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
            set(
                aggregateFields,
                fieldCursor + copy,
                locals[localBase + fieldBase + copy]);
            copy += 1;
        }
        return new AggregateAllocation(
            aggregateCount + 1,
            aggregateCount + 1,
            fieldCursor + fieldCount);
    }

    public long aggregateTag(words aggregateTags, long handle) {
        if (handle < 1) {
            return -1;
        }
        return aggregateTags[handle - 1];
    }

    public long aggregateField(
        words aggregateStarts,
        words aggregateCounts,
        words aggregateFields,
        long handle,
        long field
    ) {
        if (handle < 1) {
            return 0;
        }
        long aggregate = handle - 1;
        if (field < aggregateCounts[aggregate]) {
            return aggregateFields[aggregateStarts[aggregate] + field];
        }
        return 0;
    }
}
