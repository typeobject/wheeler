module examples.compiler.interpreter;
import examples.compiler.opcodes;
import examples.compiler.verifier;
import examples.packages.binary;
classical class Interpreter {
    public record Execution(long globalValue, long steps) {}

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
        return depth * 8 + local;
    }

    public ExecutionResult executeArtifact(
        byteview artifact,
        words locals,
        words returnCursors,
        words returnEnds
    ) {
        long fileLength = bufferLength(artifact);
        if (verifyArtifact(artifact, fileLength) == 1) {
        } else {
            return new ExecutionResult.Error(0);
        }
        long manifestOffset = sectionOffset(artifact, 0);
        long typesOffset = sectionOffset(artifact, 2);
        long functionsOffset = sectionOffset(artifact, 4);
        long codeOffset = sectionOffset(artifact, 5);
        long globalCount = readUnsigned(artifact, typesOffset, 4);
        long globalValue = 0;
        if (globalCount == 1) {
            globalValue = readSigned(artifact, typesOffset + 12);
        }
        long functionCount = readUnsigned(artifact, functionsOffset, 4);
        long entry = readUnsigned(artifact, manifestOffset + 4, 4);
        if (entry < functionCount) {
        } else {
            return new ExecutionResult.Error(manifestOffset + 4);
        }
        long entryDescriptor = descriptorBase(functionsOffset, entry);
        long cursor = codeOffset
            + readUnsigned(artifact, entryDescriptor + 12, 4);
        long end = cursor
            + readUnsigned(artifact, entryDescriptor + 16, 4);
        long depth = 0;
        long steps = 0;
        long clear = 0;
        while (clear < 8) limit 8 {
            set(locals, clear, 0);
            clear += 1;
        }
        while (steps < 512) limit 512 {
            if (end - cursor < 8) {
                return new ExecutionResult.Error(cursor);
            }
            long opcode = readUnsigned(artifact, cursor, 2);
            long instructionLength = readUnsigned(artifact, cursor + 4, 4);
            long next = cursor + instructionLength;
            if (opcode == OPCODE_HALT) {
                if (depth == 0) {
                    Execution execution = new Execution(globalValue, steps + 1);
                    return new ExecutionResult.Value(execution);
                }
                return new ExecutionResult.Error(cursor);
            }
            if (opcode == OPCODE_RETURN) {
                if (0 < depth) {
                    depth -= 1;
                    cursor = returnCursors[depth];
                    end = returnEnds[depth];
                    steps += 1;
                } else {
                    return new ExecutionResult.Error(cursor);
                }
            } else {
                if (opcode == OPCODE_ADD_CONST) {
                    globalValue += readSigned(artifact, cursor + 16);
                }
                if (opcode == OPCODE_SUB_CONST) {
                    globalValue -= readSigned(artifact, cursor + 16);
                }
                if (opcode == OPCODE_XOR_CONST) {
                    globalValue ^= readSigned(artifact, cursor + 16);
                }
                if (opcode == OPCODE_CALL) {
                    long callTarget = readUnsigned(artifact, cursor + 8, 8);
                    if (7 < depth + 1) {
                        return new ExecutionResult.Error(cursor);
                    }
                    if (callTarget < functionCount) {
                        set(returnCursors, depth, next);
                        set(returnEnds, depth, end);
                        depth += 1;
                        long callDescriptor = descriptorBase(
                            functionsOffset, callTarget);
                        cursor = codeOffset + readUnsigned(
                            artifact, callDescriptor + 12, 4);
                        end = cursor + readUnsigned(
                            artifact, callDescriptor + 16, 4);
                        long clearCall = 0;
                        while (clearCall < 8) limit 8 {
                            set(locals, localIndex(depth, clearCall), 0);
                            clearCall += 1;
                        }
                    } else {
                        return new ExecutionResult.Error(cursor);
                    }
                }
                if (opcode == OPCODE_UNCALL) {
                    long uncallTarget = readUnsigned(artifact, cursor + 8, 8);
                    if (7 < depth + 1) {
                        return new ExecutionResult.Error(cursor);
                    }
                    if (uncallTarget < functionCount) {
                        set(returnCursors, depth, next);
                        set(returnEnds, depth, end);
                        depth += 1;
                        long uncallDescriptor = descriptorBase(
                            functionsOffset, uncallTarget);
                        long forwardOffset = readUnsigned(
                            artifact, uncallDescriptor + 12, 4);
                        long inverseOffset = readUnsigned(
                            artifact, uncallDescriptor + 20, 4);
                        cursor = codeOffset + forwardOffset + inverseOffset;
                        end = cursor + readUnsigned(
                            artifact, uncallDescriptor + 24, 4);
                        long clearUncall = 0;
                        while (clearUncall < 8) limit 8 {
                            set(locals, localIndex(depth, clearUncall), 0);
                            clearUncall += 1;
                        }
                    } else {
                        return new ExecutionResult.Error(cursor);
                    }
                }
                if (opcode == OPCODE_EXPECT_EQ) {
                    long expected = readSigned(artifact, cursor + 16);
                    if (globalValue == expected) {
                    } else {
                        return new ExecutionResult.Error(cursor);
                    }
                }
                if (opcode == OPCODE_LOCAL_CONST) {
                    long constantDestination = readUnsigned(
                        artifact, cursor + 8, 8);
                    set(
                        locals,
                        localIndex(depth, constantDestination),
                        readSigned(artifact, cursor + 16));
                }
                if (opcode == OPCODE_LOCAL_LOAD_GLOBAL) {
                    long loadDestination = readUnsigned(
                        artifact, cursor + 8, 8);
                    set(locals, localIndex(depth, loadDestination), globalValue);
                }
                if (opcode == OPCODE_LOCAL_STORE_GLOBAL) {
                    long storeSource = readUnsigned(artifact, cursor + 16, 8);
                    globalValue = locals[localIndex(depth, storeSource)];
                }
                if (opcode == OPCODE_LOCAL_MOVE) {
                    long moveDestination = readUnsigned(
                        artifact, cursor + 8, 8);
                    long moveSource = readUnsigned(artifact, cursor + 16, 8);
                    set(
                        locals,
                        localIndex(depth, moveDestination),
                        locals[localIndex(depth, moveSource)]);
                }
                if (isLocalMathOpcode(opcode)) {
                    long mathDestination = readUnsigned(
                        artifact, cursor + 8, 8);
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
                if (opcode == OPCODE_CALL) {
                } else {
                    if (opcode == OPCODE_UNCALL) {
                    } else {
                        cursor = next;
                    }
                }
                steps += 1;
            }
        }
        return new ExecutionResult.Error(cursor);
    }
}
