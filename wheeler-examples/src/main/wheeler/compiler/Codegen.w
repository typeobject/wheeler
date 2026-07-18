module examples.compiler.codegen;
import examples.compiler.encoding;
classical class Codegen {
    public long globalOpcode(long opcode) {
        if (opcode == 1040) {
            return 256;
        }
        if (opcode == 1041) {
            return 257;
        }
        return 258;
    }

    public long inverseGlobalOpcode(long opcode) {
        if (opcode == 256) {
            return 257;
        }
        if (opcode == 257) {
            return 256;
        }
        return 258;
    }

    public long statementLocalCount(long opcode) {
        if (opcode == 768) {
            return 0;
        }
        if (opcode == 769) {
            return 2;
        }
        if (opcode == 0) {
            return 1;
        }
        if (0 < opcode) {
            return 2;
        }
        return 0;
    }

    public long statementCodeLength(long opcode) {
        if (opcode == 768) {
            return 24;
        }
        if (opcode == 769) {
            return 48;
        }
        if (opcode == 0) {
            return 48;
        }
        if (0 < opcode) {
            return 104;
        }
        return 0;
    }

    public long writeGlobalUpdate(
        bytes output,
        long cursor,
        long opcode,
        long operand
    ) {
        cursor = writeInstructionHeader(
            output, cursor, globalOpcode(opcode), 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    public long writeInverseGlobalUpdate(
        bytes output,
        long cursor,
        long opcode,
        long operand
    ) {
        cursor = writeInstructionHeader(
            output,
            cursor,
            inverseGlobalOpcode(globalOpcode(opcode)),
            2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    public long writeStatement(
        bytes output,
        long cursor,
        long opcode,
        long operand,
        long localBase
    ) {
        if (opcode == 768) {
            cursor = writeInstructionHeader(output, cursor, 768, 2);
            cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            return writeSignedLittleEndian(output, cursor, operand, 8);
        }
        cursor = writeInstructionHeader(output, cursor, 1024, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeSignedLittleEndian(output, cursor, operand, 8);
        if (opcode == 769) {
            cursor = writeInstructionHeader(output, cursor, 1027, 2);
            cursor = writeUnsignedLittleEndian(
                output, cursor, localBase + 1, 8);
            return writeUnsignedLittleEndian(
                output, cursor, localBase, 8);
        }
        if (opcode == 0) {
            cursor = writeInstructionHeader(output, cursor, 1026, 2);
            cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            return writeUnsignedLittleEndian(
                output, cursor, localBase, 8);
        }
        cursor = writeInstructionHeader(output, cursor, 1025, 2);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeInstructionHeader(output, cursor, opcode, 3);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeInstructionHeader(output, cursor, 1026, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeUnsignedLittleEndian(
            output, cursor, localBase + 1, 8);
    }

    public long writeFunctionDescriptor(
        bytes output,
        long cursor,
        long id,
        long name,
        long forwardOffset,
        long forwardLength,
        long flags,
        long inverseOffset,
        long inverseLength,
        long localCount,
        long typeOffset
    ) {
        cursor = writeUnsignedLittleEndian(output, cursor, id, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, name, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, flags, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, forwardOffset, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, forwardLength, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, inverseOffset, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, inverseLength, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, localCount, 4);
        return writeUnsignedLittleEndian(output, cursor, typeOffset, 4);
    }
}
