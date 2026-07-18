//! Encodes the bounded bootstrap IR as canonical Wheeler bytecode.

module wheeler.compiler.codegen;
import wheeler.compiler.encoding;
classical class Codegen {
    /// Maps a parsed global update to its canonical bytecode opcode.
    public long globalOpcode(long opcode) {
        if (opcode == 1040) {
            return 256;
        }
        if (opcode == 1041) {
            return 257;
        }
        return 258;
    }

    /// Maps a forward global opcode to its exact inverse opcode.
    public long inverseGlobalOpcode(long opcode) {
        if (opcode == 256) {
            return 257;
        }
        if (opcode == 257) {
            return 256;
        }
        return 258;
    }

    /// Returns the typed-local width required by one parsed statement.
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

    /// Returns the encoded byte width of one parsed statement.
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

    /// Writes `globalUpdate` into caller-owned bounded output.
    public long writeGlobalUpdate(bytes output, long cursor, long opcode, long operand) {
        cursor = writeInstructionHeader(output, cursor, globalOpcode(opcode), 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    /// Writes `inverseGlobalUpdate` into caller-owned bounded output.
    public long writeInverseGlobalUpdate(bytes output, long cursor, long opcode, long operand) {
        cursor = writeInstructionHeader(
            output,
            cursor,
            inverseGlobalOpcode(globalOpcode(opcode)),
            2
        );
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    /// Writes `statement` into caller-owned bounded output.
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
            cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
            return writeUnsignedLittleEndian(output, cursor, localBase, 8);
        }
        if (opcode == 0) {
            cursor = writeInstructionHeader(output, cursor, 1026, 2);
            cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
            return writeUnsignedLittleEndian(output, cursor, localBase, 8);
        }
        cursor = writeInstructionHeader(output, cursor, 1025, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        cursor = writeInstructionHeader(output, cursor, opcode, 3);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeInstructionHeader(output, cursor, 1026, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
        return writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    }

    /// Writes `functionDescriptor` into caller-owned bounded output.
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
