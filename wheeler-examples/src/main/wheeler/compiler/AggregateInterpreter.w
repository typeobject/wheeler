/// Interns bounded immutable record values for the Wheeler interpreter.
module examples.compiler.aggregate_interpreter;
import examples.compiler.opcodes;
classical class AggregateInterpreter {
    public record AggregateAllocation(
        long handle,
        long aggregateCount,
        long fieldCursor
    ) {}

    public AggregateAllocation internRecord(
        words aggregateTypes,
        words aggregateStarts,
        words aggregateCounts,
        words aggregateFields,
        words locals,
        long localBase,
        long typeId,
        long fieldBase,
        long fieldCount,
        long aggregateCount,
        long fieldCursor
    ) {
        long aggregate = 0;
        while (aggregate < aggregateCount)
            limit INTERPRETER_AGGREGATE_COUNT {
            boolean equal = aggregateTypes[aggregate] == typeId;
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
        set(aggregateTypes, aggregateCount, typeId);
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

    public long recordField(
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
