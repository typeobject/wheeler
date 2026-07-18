//! Executes verified canonical artifacts in the Wheeler bootstrap VM.

module wheeler.compiler.interpreter;
import wheeler.compiler.aggregate_interpreter;
import wheeler.compiler.opcodes;
import wheeler.compiler.storage_interpreter;
import wheeler.compiler.type_codes;
import wheeler.compiler.verifier;
import wheeler.packages.binary;
classical class Interpreter {
    /// Defines immutable `Execution` values for this module.
    public record Execution(
        long globalZero,
        long globalOne,
        long globalTwo,
        long globalThree,
        long globalFour,
        long globalFive,
        long globalSix,
        long globalSeven,
        long globalCount,
        long steps
    ) {}

    /// Defines the closed `ExecutionResult` cases exported by this module.
    public variant ExecutionResult {
        case Value(Execution execution);
        case Error(long offset);
    }

    private long readSigned(byteview artifact, long offset) {
        long value = 0;
        long multiplier = 1;
        long cursor = 0;
        while (cursor < 7) limit 7 {
            value += artifact[offset + cursor] * multiplier;
            multiplier = multiplier * 256;
            cursor += 1;
        }
        long high = artifact[offset + 7];
        if (127 < high) {
            high -= 256;
        }
        return value + high * 72057594037927936;
    }

    private long sectionOffset(byteview artifact, long section) {
        return readUnsigned(artifact, 40 + section * 32 + 8, 8);
    }

    private long descriptorBase(long functionsOffset, long function) {
        return functionsOffset + 4 + function * 40;
    }

    private long localIndex(long depth, long local) {
        return depth * INTERPRETER_LOCAL_WIDTH + local;
    }

    private long instructionCursor(byteview artifact, long start, long end, long target) {
        long cursor = start;
        long index = 0;
        while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
            if (index == target) {
                return cursor;
            }
            cursor += readUnsigned(artifact, cursor + 4, 4);
            index += 1;
        }
        return -1;
    }

    /// Executes `artifact` under explicit bootstrap bounds.
    public ExecutionResult executeArtifact(
        byteview artifact,
        words globals,
        words locals,
        words returnCursors,
        words returnStarts,
        words returnEnds,
        words returnDestinations,
        words aggregateTypes,
        words aggregateTags,
        words aggregateStarts,
        words aggregateCounts,
        words aggregateFields,
        words storageKinds,
        words storageStarts,
        words storageLengths,
        words storageSizes,
        words storageOwners,
        words storageLive,
        words storageRegionUsedBytes,
        words storageRegionLiveObjects,
        words storageData
    ) {
        long fileLength = bufferLength(artifact);
        if (verifyArtifact(artifact, fileLength) == 1) {} else {
            return new ExecutionResult.Error(0);
        }
        long manifestOffset = sectionOffset(artifact, 0);
        long typesOffset = sectionOffset(artifact, 2);
        long functionsOffset = sectionOffset(artifact, 4);
        long codeOffset = sectionOffset(artifact, 5);
        long globalCount = readUnsigned(artifact, typesOffset, 4);
        long global = 0;
        while (global < globalCount) limit INTERPRETER_GLOBAL_COUNT {
            set(globals, global, readSigned(artifact, typesOffset + 12 + global * 16));
            global += 1;
        }
        long functionCount = readUnsigned(artifact, functionsOffset, 4);
        long entry = readUnsigned(artifact, manifestOffset + 4, 4);
        if (entry < functionCount) {} else {
            return new ExecutionResult.Error(manifestOffset + 4);
        }
        long entryDescriptor = descriptorBase(functionsOffset, entry);
        long cursor = codeOffset + readUnsigned(artifact, entryDescriptor + 12, 4);
        long start = cursor;
        long end = cursor + readUnsigned(artifact, entryDescriptor + 16, 4);
        long depth = 0;
        long aggregateCount = 0;
        long aggregateFieldCursor = 0;
        long storageCount = 0;
        long storageDataCursor = 0;
        long steps = 0;
        long clear = 0;
        while (clear < readUnsigned(artifact, entryDescriptor
            + 32, 4)) limit INTERPRETER_LOCAL_WIDTH {
            set(locals, clear, 0);
            clear += 1;
        }
        while (steps < MAX_INTERPRETED_STEPS) limit MAX_INTERPRETED_STEPS {
            if (end - cursor < 8) {
                return new ExecutionResult.Error(cursor);
            }
            long opcode = readUnsigned(artifact, cursor, 2);
            long instructionLength = readUnsigned(artifact, cursor + 4, 4);
            long next = cursor + instructionLength;
            if (opcode == OPCODE_HALT) {
                if (depth == 0) {
                    Execution execution = new Execution(
                        globals[0],
                        globals[1],
                        globals[2],
                        globals[3],
                        globals[4],
                        globals[5],
                        globals[6],
                        globals[7],
                        globalCount,
                        steps + 1
                    );
                    return new ExecutionResult.Value(execution);
                }
                return new ExecutionResult.Error(cursor);
            }
            if (opcode == OPCODE_RETURN) {
                if (0 < depth) {
                    depth -= 1;
                    if (returnDestinations[depth] < 0) {
                        cursor = returnCursors[depth];
                        start = returnStarts[depth];
                        end = returnEnds[depth];
                        steps += 1;
                    } else {
                        return new ExecutionResult.Error(cursor);
                    }
                } else {
                    return new ExecutionResult.Error(cursor);
                }
            } else {
                if (opcode == OPCODE_RETURN_VALUE) {
                    if (0 < depth) {
                        long returnSource = readUnsigned(artifact, cursor + 8, 8);
                        long returnValue = locals[localIndex(depth, returnSource)];
                        depth -= 1;
                        long returnDestination = returnDestinations[depth];
                        if (returnDestination < 0) {
                            return new ExecutionResult.Error(cursor);
                        }
                        cursor = returnCursors[depth];
                        start = returnStarts[depth];
                        end = returnEnds[depth];
                        set(locals, localIndex(depth, returnDestination), returnValue);
                        steps += 1;
                    } else {
                        return new ExecutionResult.Error(cursor);
                    }
                } else {
                    if (opcode == OPCODE_ADD_CONST) {
                        long addGlobal = readUnsigned(artifact, cursor + 8, 8);
                        set(
                            globals,
                            addGlobal,
                            globals[addGlobal] + readSigned(artifact, cursor + 16)
                        );
                    }
                    if (opcode == OPCODE_SUB_CONST) {
                        long subtractGlobal = readUnsigned(artifact, cursor + 8, 8);
                        set(
                            globals,
                            subtractGlobal,
                            globals[subtractGlobal] - readSigned(artifact, cursor + 16)
                        );
                    }
                    if (opcode == OPCODE_XOR_CONST) {
                        long xorGlobal = readUnsigned(artifact, cursor + 8, 8);
                        set(
                            globals,
                            xorGlobal,
                            globals[xorGlobal] ^ readSigned(artifact, cursor + 16)
                        );
                    }
                    if (opcode == OPCODE_CALL) {
                        long callTarget = readUnsigned(artifact, cursor + 8, 8);
                        if (INTERPRETER_MAX_CALL_DEPTH < depth + 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (callTarget < functionCount) {
                            set(returnCursors, depth, next);
                            set(returnStarts, depth, start);
                            set(returnEnds, depth, end);
                            set(returnDestinations, depth, -1);
                            depth += 1;
                            long callDescriptor = descriptorBase(functionsOffset, callTarget);
                            cursor = codeOffset + readUnsigned(artifact, callDescriptor + 12, 4);
                            start = cursor;
                            end = cursor + readUnsigned(artifact, callDescriptor + 16, 4);
                            long clearCall = 0;
                            while (clearCall < readUnsigned(artifact, callDescriptor
                                + 32, 4)) limit INTERPRETER_LOCAL_WIDTH {
                                set(locals, localIndex(depth, clearCall), 0);
                                clearCall += 1;
                            }
                        } else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_UNCALL) {
                        long uncallTarget = readUnsigned(artifact, cursor + 8, 8);
                        if (INTERPRETER_MAX_CALL_DEPTH < depth + 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (uncallTarget < functionCount) {
                            set(returnCursors, depth, next);
                            set(returnStarts, depth, start);
                            set(returnEnds, depth, end);
                            set(returnDestinations, depth, -1);
                            depth += 1;
                            long uncallDescriptor = descriptorBase(functionsOffset, uncallTarget);
                            long forwardOffset = readUnsigned(artifact, uncallDescriptor + 12, 4);
                            long inverseOffset = readUnsigned(artifact, uncallDescriptor + 20, 4);
                            cursor = codeOffset + forwardOffset + inverseOffset;
                            start = cursor;
                            end = cursor + readUnsigned(artifact, uncallDescriptor + 24, 4);
                            long clearUncall = 0;
                            while (
                                clearUncall < readUnsigned(artifact, uncallDescriptor + 32, 4)
                            ) limit INTERPRETER_LOCAL_WIDTH {
                                set(locals, localIndex(depth, clearUncall), 0);
                                clearUncall += 1;
                            }
                        } else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_CALL_VALUE) {
                        long valueTarget = readUnsigned(artifact, cursor + 8, 8);
                        long valueArgumentBase = readUnsigned(artifact, cursor + 16, 8);
                        long valueArgumentCount = readUnsigned(artifact, cursor + 24, 8);
                        long valueDestination = readUnsigned(artifact, cursor + 32, 8);
                        if (INTERPRETER_MAX_CALL_DEPTH < depth + 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (valueTarget < functionCount) {
                            set(returnCursors, depth, next);
                            set(returnStarts, depth, start);
                            set(returnEnds, depth, end);
                            set(returnDestinations, depth, valueDestination);
                            depth += 1;
                            long valueDescriptor = descriptorBase(functionsOffset, valueTarget);
                            cursor = codeOffset + readUnsigned(artifact, valueDescriptor + 12, 4);
                            start = cursor;
                            end = cursor + readUnsigned(artifact, valueDescriptor + 16, 4);
                            long clearValue = 0;
                            while (clearValue < readUnsigned(artifact, valueDescriptor
                                + 32, 4)) limit INTERPRETER_LOCAL_WIDTH {
                                set(locals, localIndex(depth, clearValue), 0);
                                clearValue += 1;
                            }
                            long copyValue = 0;
                            while (copyValue < valueArgumentCount) limit INTERPRETER_LOCAL_WIDTH {
                                set(
                                    locals,
                                    localIndex(depth, copyValue),
                                    locals[localIndex(depth - 1, valueArgumentBase + copyValue)]
                                );
                                copyValue += 1;
                            }
                        } else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_CALL_VOID) {
                        long voidTarget = readUnsigned(artifact, cursor + 8, 8);
                        long voidArgumentBase = readUnsigned(artifact, cursor + 16, 8);
                        long voidArgumentCount = readUnsigned(artifact, cursor + 24, 8);
                        if (INTERPRETER_MAX_CALL_DEPTH < depth + 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (voidTarget < functionCount) {
                            set(returnCursors, depth, next);
                            set(returnStarts, depth, start);
                            set(returnEnds, depth, end);
                            set(returnDestinations, depth, -1);
                            depth += 1;
                            long voidDescriptor = descriptorBase(functionsOffset, voidTarget);
                            cursor = codeOffset + readUnsigned(artifact, voidDescriptor + 12, 4);
                            start = cursor;
                            end = cursor + readUnsigned(artifact, voidDescriptor + 16, 4);
                            long clearVoid = 0;
                            while (clearVoid < readUnsigned(artifact, voidDescriptor
                                + 32, 4)) limit INTERPRETER_LOCAL_WIDTH {
                                set(locals, localIndex(depth, clearVoid), 0);
                                clearVoid += 1;
                            }
                            long copyVoid = 0;
                            while (copyVoid < voidArgumentCount) limit INTERPRETER_LOCAL_WIDTH {
                                set(
                                    locals,
                                    localIndex(depth, copyVoid),
                                    locals[localIndex(depth - 1, voidArgumentBase + copyVoid)]
                                );
                                copyVoid += 1;
                            }
                        } else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_EXPECT_EQ) {
                        long expectedGlobal = readUnsigned(artifact, cursor + 8, 8);
                        long expected = readSigned(artifact, cursor + 16);
                        if (globals[expectedGlobal] == expected) {} else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_LOCAL_CONST) {
                        long constantDestination = readUnsigned(artifact, cursor + 8, 8);
                        set(
                            locals,
                            localIndex(depth, constantDestination),
                            readSigned(artifact, cursor + 16)
                        );
                    }
                    if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
                        long loadDestination = readUnsigned(artifact, cursor + 8, 8);
                        long loadGlobal = readUnsigned(artifact, cursor + 16, 8);
                        set(locals, localIndex(depth, loadDestination), globals[loadGlobal]);
                    }
                    if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
                        long storeGlobal = readUnsigned(artifact, cursor + 8, 8);
                        long storeSource = readUnsigned(artifact, cursor + 16, 8);
                        set(globals, storeGlobal, locals[localIndex(depth, storeSource)]);
                    }
                    if (opcode == OPCODE_LOCAL_MOVE) {
                        long moveDestination = readUnsigned(artifact, cursor + 8, 8);
                        long moveSource = readUnsigned(artifact, cursor + 16, 8);
                        set(
                            locals,
                            localIndex(depth, moveDestination),
                            locals[localIndex(depth, moveSource)]
                        );
                    }
                    if (isLocalMathOpcode(opcode)) {
                        long mathDestination = readUnsigned(artifact, cursor + 8, 8);
                        long left = readUnsigned(artifact, cursor + 16, 8);
                        long right = readUnsigned(artifact, cursor + 24, 8);
                        long leftValue = locals[localIndex(depth, left)];
                        long rightValue = locals[localIndex(depth, right)];
                        long result = 0;
                        if (opcode == OPCODE_LOCAL_ADD) {
                            result = leftValue + rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_SUB) {
                            result = leftValue - rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_XOR) {
                            result = leftValue ^ rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_MUL) {
                            result = leftValue * rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_DIV) {
                            result = leftValue / rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_MOD) {
                            result = leftValue % rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_AND) {
                            result = leftValue & rightValue;
                        }
                        if (opcode == OPCODE_LOCAL_ROTR32) {
                            result = rotateRight32(leftValue, rightValue);
                        }
                        set(locals, localIndex(depth, mathDestination), result);
                    }
                    if (opcode == OPCODE_RECORD_NEW) {
                        long recordDestination = readUnsigned(artifact, cursor + 8, 8);
                        long recordType = readUnsigned(artifact, cursor + 16, 8);
                        long recordBase = readUnsigned(artifact, cursor + 24, 8);
                        long recordCount = readUnsigned(artifact, cursor + 32, 8);
                        AggregateAllocation allocation = internAggregate(
                            aggregateTypes,
                            aggregateTags,
                            aggregateStarts,
                            aggregateCounts,
                            aggregateFields,
                            locals,
                            depth * INTERPRETER_LOCAL_WIDTH,
                            TYPE_RECORD + recordType,
                            0,
                            recordBase,
                            recordCount,
                            aggregateCount,
                            aggregateFieldCursor
                        );
                        if (allocation.handle < 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        aggregateCount = allocation.aggregateCount;
                        aggregateFieldCursor = allocation.fieldCursor;
                        set(locals, localIndex(depth, recordDestination), allocation.handle);
                    }
                    if (opcode == OPCODE_RECORD_GET) {
                        long fieldDestination = readUnsigned(artifact, cursor + 8, 8);
                        long recordSource = readUnsigned(artifact, cursor + 16, 8);
                        long recordFieldIndex = readUnsigned(artifact, cursor + 24, 8);
                        long recordHandle = locals[localIndex(depth, recordSource)];
                        set(
                            locals,
                            localIndex(depth, fieldDestination),
                            aggregateField(
                                aggregateStarts,
                                aggregateCounts,
                                aggregateFields,
                                recordHandle,
                                recordFieldIndex
                            )
                        );
                    }
                    if (opcode < OPCODE_OWNED_MOVE) {} else {
                        if (OPCODE_REGION_BORROW < opcode) {} else {
                            StorageStep storageStep = executeStorageInstruction(
                                artifact,
                                cursor,
                                opcode,
                                locals,
                                depth,
                                storageKinds,
                                storageStarts,
                                storageLengths,
                                storageSizes,
                                storageOwners,
                                storageLive,
                                storageRegionUsedBytes,
                                storageRegionLiveObjects,
                                storageData,
                                storageCount,
                                storageDataCursor
                            );
                            match (storageStep) {
                                case StorageStep.Skipped() {}
                                case StorageStep.Value(
                                    long nextStorageCount,
                                    long nextStorageDataCursor
                                ) {
                                    storageCount = nextStorageCount;
                                    storageDataCursor = nextStorageDataCursor;
                                }
                                case StorageStep.Error() {
                                    return new ExecutionResult.Error(cursor);
                                }
                            }
                        }
                    }
                    if (opcode == OPCODE_ARRAY_NEW) {
                        long arrayDestination = readUnsigned(artifact, cursor + 8, 8);
                        long arrayType = readUnsigned(artifact, cursor + 16, 8);
                        long elementBase = readUnsigned(artifact, cursor + 24, 8);
                        long elementCount = readUnsigned(artifact, cursor + 32, 8);
                        AggregateAllocation arrayAllocation = internAggregate(
                            aggregateTypes,
                            aggregateTags,
                            aggregateStarts,
                            aggregateCounts,
                            aggregateFields,
                            locals,
                            depth * INTERPRETER_LOCAL_WIDTH,
                            TYPE_ARRAY + arrayType,
                            0,
                            elementBase,
                            elementCount,
                            aggregateCount,
                            aggregateFieldCursor
                        );
                        if (arrayAllocation.handle < 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        aggregateCount = arrayAllocation.aggregateCount;
                        aggregateFieldCursor = arrayAllocation.fieldCursor;
                        set(locals, localIndex(depth, arrayDestination), arrayAllocation.handle);
                    }
                    if (opcode == OPCODE_ARRAY_GET) {
                        long arrayGetDestination = readUnsigned(artifact, cursor + 8, 8);
                        long arraySource = readUnsigned(artifact, cursor + 16, 8);
                        long arrayIndexLocal = readUnsigned(artifact, cursor + 24, 8);
                        long arrayIndex = locals[localIndex(depth, arrayIndexLocal)];
                        long arrayHandle = locals[localIndex(depth, arraySource)];
                        if (aggregateFieldValid(aggregateCounts, arrayHandle, arrayIndex)) {} else {
                            return new ExecutionResult.Error(cursor);
                        }
                        set(
                            locals,
                            localIndex(depth, arrayGetDestination),
                            aggregateField(
                                aggregateStarts,
                                aggregateCounts,
                                aggregateFields,
                                arrayHandle,
                                arrayIndex
                            )
                        );
                    }
                    if (opcode == OPCODE_SLICE_NEW) {
                        long sliceDestination = readUnsigned(artifact, cursor + 8, 8);
                        long sliceType = readUnsigned(artifact, cursor + 16, 8);
                        long sliceArray = readUnsigned(artifact, cursor + 24, 8);
                        long sliceStartLocal = readUnsigned(artifact, cursor + 32, 8);
                        long sliceLengthLocal = readUnsigned(artifact, cursor + 40, 8);
                        long sliceArrayHandle = locals[localIndex(depth, sliceArray)];
                        long sliceStart = locals[localIndex(depth, sliceStartLocal)];
                        long sliceLength = locals[localIndex(depth, sliceLengthLocal)];
                        if (
                            aggregateWindowValid(
                                aggregateCounts,
                                sliceArrayHandle,
                                sliceStart,
                                sliceLength
                            )
                        ) {} else {
                            return new ExecutionResult.Error(cursor);
                        }
                        AggregateAllocation sliceAllocation = internSlice(
                            aggregateTypes,
                            aggregateTags,
                            aggregateStarts,
                            aggregateCounts,
                            aggregateFields,
                            sliceArrayHandle,
                            sliceStart,
                            sliceLength,
                            TYPE_SLICE + sliceType,
                            aggregateCount,
                            aggregateFieldCursor
                        );
                        if (sliceAllocation.handle < 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        aggregateCount = sliceAllocation.aggregateCount;
                        aggregateFieldCursor = sliceAllocation.fieldCursor;
                        set(locals, localIndex(depth, sliceDestination), sliceAllocation.handle);
                    }
                    if (opcode == OPCODE_SLICE_GET) {
                        long sliceGetDestination = readUnsigned(artifact, cursor + 8, 8);
                        long sliceSource = readUnsigned(artifact, cursor + 16, 8);
                        long sliceIndexLocal = readUnsigned(artifact, cursor + 24, 8);
                        long sliceIndex = locals[localIndex(depth, sliceIndexLocal)];
                        long sliceHandle = locals[localIndex(depth, sliceSource)];
                        if (aggregateFieldValid(aggregateCounts, sliceHandle, sliceIndex)) {} else {
                            return new ExecutionResult.Error(cursor);
                        }
                        set(
                            locals,
                            localIndex(depth, sliceGetDestination),
                            aggregateField(
                                aggregateStarts,
                                aggregateCounts,
                                aggregateFields,
                                sliceHandle,
                                sliceIndex
                            )
                        );
                    }
                    if (opcode == OPCODE_VARIANT_NEW) {
                        long variantDestination = readUnsigned(artifact, cursor + 8, 8);
                        long variantType = readUnsigned(artifact, cursor + 16, 8);
                        long variantTag = readUnsigned(artifact, cursor + 24, 8);
                        long variantBase = readUnsigned(artifact, cursor + 32, 8);
                        long variantFields = readUnsigned(artifact, cursor + 40, 8);
                        AggregateAllocation variantAllocation = internAggregate(
                            aggregateTypes,
                            aggregateTags,
                            aggregateStarts,
                            aggregateCounts,
                            aggregateFields,
                            locals,
                            depth * INTERPRETER_LOCAL_WIDTH,
                            TYPE_VARIANT + variantType,
                            variantTag,
                            variantBase,
                            variantFields,
                            aggregateCount,
                            aggregateFieldCursor
                        );
                        if (variantAllocation.handle < 1) {
                            return new ExecutionResult.Error(cursor);
                        }
                        aggregateCount = variantAllocation.aggregateCount;
                        aggregateFieldCursor = variantAllocation.fieldCursor;
                        set(
                            locals,
                            localIndex(depth, variantDestination),
                            variantAllocation.handle
                        );
                    }
                    if (opcode == OPCODE_VARIANT_TAG_EQ) {
                        long tagDestination = readUnsigned(artifact, cursor + 8, 8);
                        long tagSource = readUnsigned(artifact, cursor + 16, 8);
                        long expectedTag = readUnsigned(artifact, cursor + 24, 8);
                        long variantHandle = locals[localIndex(depth, tagSource)];
                        long tagMatches = 0;
                        if (aggregateTag(aggregateTags, variantHandle) == expectedTag) {
                            tagMatches = 1;
                        }
                        set(locals, localIndex(depth, tagDestination), tagMatches);
                    }
                    if (opcode == OPCODE_VARIANT_GET) {
                        long getDestination = readUnsigned(artifact, cursor + 8, 8);
                        long getSource = readUnsigned(artifact, cursor + 16, 8);
                        long getTag = readUnsigned(artifact, cursor + 24, 8);
                        long getField = readUnsigned(artifact, cursor + 32, 8);
                        long getHandle = locals[localIndex(depth, getSource)];
                        if (aggregateTag(aggregateTags, getHandle) == getTag) {} else {
                            return new ExecutionResult.Error(cursor);
                        }
                        set(
                            locals,
                            localIndex(depth, getDestination),
                            aggregateField(
                                aggregateStarts,
                                aggregateCounts,
                                aggregateFields,
                                getHandle,
                                getField
                            )
                        );
                    }
                    if (opcode == OPCODE_LOCAL_EQ) {
                        long equalityDestination = readUnsigned(artifact, cursor + 8, 8);
                        long equalityLeft = readUnsigned(artifact, cursor + 16, 8);
                        long equalityRight = readUnsigned(artifact, cursor + 24, 8);
                        long equalityValue = 0;
                        if (
                            locals[localIndex(depth, equalityLeft)] == locals[localIndex(
                                depth,
                                equalityRight
                            )]
                        ) {
                            equalityValue = 1;
                        }
                        set(locals, localIndex(depth, equalityDestination), equalityValue);
                    }
                    if (opcode == OPCODE_LOCAL_LT) {
                        long lessDestination = readUnsigned(artifact, cursor + 8, 8);
                        long lessLeft = readUnsigned(artifact, cursor + 16, 8);
                        long lessRight = readUnsigned(artifact, cursor + 24, 8);
                        long lessValue = 0;
                        if (
                            locals[localIndex(depth, lessLeft)] < locals[localIndex(
                                depth,
                                lessRight
                            )]
                        ) {
                            lessValue = 1;
                        }
                        set(locals, localIndex(depth, lessDestination), lessValue);
                    }
                    if (opcode == OPCODE_JUMP) {
                        long jumpTarget = readUnsigned(artifact, cursor + 8, 8);
                        next = instructionCursor(artifact, start, end, jumpTarget);
                        if (next < 0) {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_JUMP_IF_ZERO) {
                        long condition = readUnsigned(artifact, cursor + 8, 8);
                        if (locals[localIndex(depth, condition)] == 0) {
                            long conditionalTarget = readUnsigned(artifact, cursor + 16, 8);
                            next = instructionCursor(artifact, start, end, conditionalTarget);
                            if (next < 0) {
                                return new ExecutionResult.Error(cursor);
                            }
                        }
                    }
                    if (opcode == OPCODE_LOCAL_LOOP_CHECK) {
                        long iterationLocal = readUnsigned(artifact, cursor + 8, 8);
                        long limitLocal = readUnsigned(artifact, cursor + 16, 8);
                        long iteration = locals[localIndex(depth, iterationLocal)];
                        long loopLimit = locals[localIndex(depth, limitLocal)];
                        if (iteration < 0) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (loopLimit < 0) {
                            return new ExecutionResult.Error(cursor);
                        }
                        if (iteration < loopLimit) {
                            set(locals, localIndex(depth, iterationLocal), iteration + 1);
                        } else {
                            return new ExecutionResult.Error(cursor);
                        }
                    }
                    if (opcode == OPCODE_CALL) {} else {
                        if (opcode == OPCODE_UNCALL) {} else {
                            if (opcode == OPCODE_CALL_VALUE) {} else {
                                if (opcode == OPCODE_CALL_VOID) {} else {
                                    cursor = next;
                                }
                            }
                        }
                    }
                    steps += 1;
                }
            }
        }
        return new ExecutionResult.Error(cursor);
    }
}
