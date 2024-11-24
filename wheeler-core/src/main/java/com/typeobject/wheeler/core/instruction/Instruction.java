package com.typeobject.wheeler.core.instruction;

import com.typeobject.wheeler.core.exceptions.InvalidInstructionException;
import org.checkerframework.checker.nullness.qual.Nullable;

import java.util.Objects;

/**
 * Represents a Wheeler VM instruction.
 *
 * <p>Format (128 bits total): - Opcode: 8 bits (byte) - Flags: 8 bits (byte) - Registers: 16 bits
 * (short) - Operand: 64 bits (long) - History: 32 bits (int)
 */
public class Instruction {
  /** Size of instruction in bytes */
  public static final int SIZE = 16; // 128 bits = 16 bytes

  private final byte opcode; // 8 bits
  private final byte flags; // 8 bits
  private final short registers; // 16 bits
  private final long operand; // 64 bits
  private final int history; // 32 bits

  public Instruction(byte opcode, byte flags, short registers, long operand, int history) {
    this.opcode = opcode;
    this.flags = flags;
    this.registers = registers;
    this.operand = operand;
    this.history = history;
  }

  /** Construct instruction from raw bytes */
  public static Instruction fromBytes(byte[] bytes) {
    if (bytes.length != SIZE) {
      throw new InvalidInstructionException(
          "Invalid instruction size: " + bytes.length + " bytes (expected " + SIZE + ")");
    }

    byte opcode = bytes[0];
    byte flags = bytes[1];
    short registers = (short) ((bytes[2] << 8) | (bytes[3] & 0xFF));

    long operand = 0;
    for (int i = 0; i < 8; i++) {
      operand = (operand << 8) | (bytes[4 + i] & 0xFF);
    }

    int history =
        ((bytes[12] & 0xFF) << 24)
            | ((bytes[13] & 0xFF) << 16)
            | ((bytes[14] & 0xFF) << 8)
            | (bytes[15] & 0xFF);

    return new Instruction(opcode, flags, registers, operand, history);
  }

  /** Convert instruction to byte array */
  public byte[] toBytes() {
    byte[] bytes = new byte[SIZE];

    bytes[0] = opcode;
    bytes[1] = flags;
    bytes[2] = (byte) (registers >> 8);
    bytes[3] = (byte) registers;

    for (int i = 0; i < 8; i++) {
      bytes[4 + i] = (byte) (operand >> ((7 - i) * 8));
    }

    bytes[12] = (byte) (history >> 24);
    bytes[13] = (byte) (history >> 16);
    bytes[14] = (byte) (history >> 8);
    bytes[15] = (byte) history;

    return bytes;
  }

  public byte getOpcode() {
    return opcode;
  }

  public byte getFlags() {
    return flags;
  }

  public short getRegisters() {
    return registers;
  }

  public long getOperand() {
    return operand;
  }

  public int getHistory() {
    return history;
  }

  public boolean isForward() {
    return (flags & InstructionSet.Flags.REVERSE) == 0;
  }

  public boolean tracksHistory() {
    return (flags & InstructionSet.Flags.HISTORY) != 0;
  }

  public boolean isAtomic() {
    return (flags & InstructionSet.Flags.ATOMIC) != 0;
  }

  public boolean isInterThread() {
    return (flags & InstructionSet.Flags.INTERTHREAD) != 0;
  }

  /**
   * Get register number from register field
   *
   * @param index 0 for first register, 1 for second
   * @return register number
   */
  public byte getRegister(int index) {
    if (index < 0 || index > 1) {
      throw new IllegalArgumentException("Invalid register index: " + index);
    }
    return (byte) (index == 0 ? (registers >> 8) : registers);
  }

  @Override
  public String toString() {
    return String.format(
        "%s [flags=%02x, reg=%04x, operand=%016x, hist=%08x]",
        InstructionSet.getInstructionName(opcode), flags, registers, operand, history);
  }

  @Override
  public boolean equals(@Nullable Object o) {
    if (this == o) return true;
    if (!(o instanceof Instruction)) return false;
    Instruction that = (Instruction) o;
    return opcode == that.opcode
            && flags == that.flags
            && registers == that.registers
            && operand == that.operand
            && history == that.history;
  }

  @Override
  public int hashCode() {
    return Objects.hash(opcode, flags, registers, operand, history);
  }
}
