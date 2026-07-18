//! Interns bounded immutable record and finite-variant values.
module wheeler.compiler.aggregate_interpreter;
import wheeler.compiler.opcodes;
classical class AggregateInterpreter {
    /// Defines immutable `AggregateAllocation` values for this module.
    public record AggregateAllocation(long handle, long aggregateCount, long fieldCursor) {}

    /// Interns one structural aggregate and returns its stable store index.
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
        while (aggregate < aggregateCount) limit INTERPRETER_AGGREGATE_COUNT {
            boolean equal = aggregateTypes[aggregate] == typeCode;
            if (aggregateTags[aggregate] == tag) {} else {
                equal = false;
            }
            if (aggregateCounts[aggregate] == fieldCount) {} else {
                equal = false;
            }
            long field = 0;
            while (field < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
                if (
                    aggregateFields[aggregateStarts[aggregate] + field] == locals[localBase
                        + fieldBase + field]
                ) {} else {
                    equal = false;
                }
                field += 1;
            }
            if (equal) {
                return new AggregateAllocation(aggregate + 1, aggregateCount, fieldCursor);
            }
            aggregate += 1;
        }
        if (aggregateCount < INTERPRETER_AGGREGATE_COUNT) {} else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        if (fieldCursor + fieldCount < INTERPRETER_AGGREGATE_FIELDS + 1) {} else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        set(aggregateTypes, aggregateCount, typeCode);
        set(aggregateTags, aggregateCount, tag);
        set(aggregateStarts, aggregateCount, fieldCursor);
        set(aggregateCounts, aggregateCount, fieldCount);
        long copy = 0;
        while (copy < fieldCount) limit INTERPRETER_LOCAL_WIDTH {
            set(aggregateFields, fieldCursor + copy, locals[localBase + fieldBase + copy]);
            copy += 1;
        }
        return new AggregateAllocation(
            aggregateCount + 1,
            aggregateCount + 1,
            fieldCursor + fieldCount
        );
    }

    /// Interns one bounded slice view and returns its stable store index.
    public AggregateAllocation internSlice(
        words aggregateTypes,
        words aggregateTags,
        words aggregateStarts,
        words aggregateCounts,
        words aggregateFields,
        long sourceHandle,
        long sourceStart,
        long sliceLength,
        long typeCode,
        long aggregateCount,
        long fieldCursor
    ) {
        long source = sourceHandle - 1;
        long aggregate = 0;
        while (aggregate < aggregateCount) limit INTERPRETER_AGGREGATE_COUNT {
            boolean equal = aggregateTypes[aggregate] == typeCode;
            if (aggregateCounts[aggregate] == sliceLength) {} else {
                equal = false;
            }
            long field = 0;
            while (field < sliceLength) limit INTERPRETER_AGGREGATE_FIELDS {
                if (
                    aggregateFields[aggregateStarts[aggregate] + field]
                        == aggregateFields[aggregateStarts[source] + sourceStart + field]
                ) {} else {
                    equal = false;
                }
                field += 1;
            }
            if (equal) {
                return new AggregateAllocation(aggregate + 1, aggregateCount, fieldCursor);
            }
            aggregate += 1;
        }
        if (aggregateCount < INTERPRETER_AGGREGATE_COUNT) {} else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        if (fieldCursor + sliceLength < INTERPRETER_AGGREGATE_FIELDS + 1) {} else {
            return new AggregateAllocation(0, aggregateCount, fieldCursor);
        }
        set(aggregateTypes, aggregateCount, typeCode);
        set(aggregateTags, aggregateCount, 0);
        set(aggregateStarts, aggregateCount, fieldCursor);
        set(aggregateCounts, aggregateCount, sliceLength);
        long copy = 0;
        while (copy < sliceLength) limit INTERPRETER_AGGREGATE_FIELDS {
            set(
                aggregateFields,
                fieldCursor + copy,
                aggregateFields[aggregateStarts[source] + sourceStart + copy]
            );
            copy += 1;
        }
        return new AggregateAllocation(
            aggregateCount + 1,
            aggregateCount + 1,
            fieldCursor + sliceLength
        );
    }

    /// Returns the stored tag for one aggregate index.
    public long aggregateTag(words aggregateTags, long handle) {
        if (handle < 1) {
            return -1;
        }
        return aggregateTags[handle - 1];
    }

    /// Checks that an aggregate field window remains inside its stored value.
    public boolean aggregateWindowValid(
        words aggregateCounts,
        long handle,
        long start,
        long length
    ) {
        if (handle < 1) {
            return false;
        }
        if (start < 0) {
            return false;
        }
        if (length < 0) {
            return false;
        }
        long count = aggregateCounts[handle - 1];
        if (count < start) {
            return false;
        }
        return length < count - start + 1;
    }

    /// Checks that one aggregate field equals the requested signed value.
    public boolean aggregateFieldValid(words aggregateCounts, long handle, long field) {
        if (handle < 1) {
            return false;
        }
        if (field < 0) {
            return false;
        }
        return field < aggregateCounts[handle - 1];
    }

    /// Returns one checked signed field from an interned aggregate.
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
