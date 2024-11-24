
package com.typeobject.wheeler.core.exceptions;

public class InvalidInstructionException extends WheelerExecutionException {
    private final byte opcode;
    private final long address;

    public InvalidInstructionException(String message) {
        super(message);
        this.opcode = 0;
        this.address = 0;
    }

    public InvalidInstructionException(String message, byte opcode, long address) {
        super(String.format("%s (opcode: 0x%02X, address: 0x%016X)", message, opcode, address));
        this.opcode = opcode;
        this.address = address;
    }

    public byte getOpcode() {
        return opcode;
    }

    public long getAddress() {
        return address;
    }
}