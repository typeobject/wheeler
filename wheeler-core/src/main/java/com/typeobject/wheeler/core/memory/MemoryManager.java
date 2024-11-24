package com.typeobject.wheeler.core.memory;

import com.typeobject.wheeler.core.exceptions.MemoryException;

public class MemoryManager {
  // Memory segments
  private final byte[] codeSegment;
  private final byte[] dataSegment;
  private final byte[] stackSegment;
  private final byte[] historySegment;

  private static final int SEGMENT_SIZE = 1 << 20; // 1MB per segment
  private static final long CODE_BASE = 0x0100_0000_0000_0000L;
  private static final long DATA_BASE = 0x0200_0000_0000_0000L;
  private static final long STACK_BASE = 0x0300_0000_0000_0000L;
  private static final long HISTORY_BASE = 0x0400_0000_0000_0000L;

  public MemoryManager() {
    this.codeSegment = new byte[SEGMENT_SIZE];
    this.dataSegment = new byte[SEGMENT_SIZE];
    this.stackSegment = new byte[SEGMENT_SIZE];
    this.historySegment = new byte[SEGMENT_SIZE];
  }

  /** Load program bytecode into code segment */
  public void load(byte[] bytecode) {
    if (bytecode.length > SEGMENT_SIZE) {
      throw new MemoryException("Program too large");
    }
    System.arraycopy(bytecode, 0, codeSegment, 0, bytecode.length);
  }

  /** Read a word from memory */
  public long readWord(long address) {
    byte[] segment = getSegment(address);
    int offset = getOffset(address);

    if (offset + 8 > segment.length) {
      throw new MemoryException("Memory access out of bounds");
    }

    return ((long) segment[offset] << 56)
        | ((long) segment[offset + 1] << 48)
        | ((long) segment[offset + 2] << 40)
        | ((long) segment[offset + 3] << 32)
        | ((long) segment[offset + 4] << 24)
        | ((long) segment[offset + 5] << 16)
        | ((long) segment[offset + 6] << 8)
        | ((long) segment[offset + 7]);
  }

  /** Write a word to memory with history tracking */
  public void writeWord(long address, long value) {
    byte[] segment = getSegment(address);
    int offset = getOffset(address);

    // Save old value to history
    long oldValue = readWord(address);
    recordHistory(address, oldValue);

    // Write new value
    segment[offset] = (byte) (value >> 56);
    segment[offset + 1] = (byte) (value >> 48);
    segment[offset + 2] = (byte) (value >> 40);
    segment[offset + 3] = (byte) (value >> 32);
    segment[offset + 4] = (byte) (value >> 24);
    segment[offset + 5] = (byte) (value >> 16);
    segment[offset + 6] = (byte) (value >> 8);
    segment[offset + 7] = (byte) value;
  }

  private byte[] getSegment(long address) {
    if (address >= CODE_BASE && address < DATA_BASE) {
      return codeSegment;
    } else if (address >= DATA_BASE && address < STACK_BASE) {
      return dataSegment;
    } else if (address >= STACK_BASE && address < HISTORY_BASE) {
      return stackSegment;
    } else if (address >= HISTORY_BASE) {
      return historySegment;
    }
    throw new MemoryException("Invalid memory address: " + Long.toHexString(address));
  }

  private int getOffset(long address) {
    return (int) (address & 0xFFFFF); // Bottom 20 bits
  }

  private void recordHistory(long address, long oldValue) {
    // Record in history segment for reverse execution
    long historyAddress = HISTORY_BASE + getHistoryOffset();
    byte[] segment = getSegment(historyAddress);
    int offset = getOffset(historyAddress);

    // History record format: address (8 bytes) + old value (8 bytes)
    System.arraycopy(longToBytes(address), 0, segment, offset, 8);
    System.arraycopy(longToBytes(oldValue), 0, segment, offset + 8, 8);
  }

  private long historyOffset = 0;

  private long getHistoryOffset() {
    long offset = historyOffset;
    historyOffset += 16; // Each history record is 16 bytes
    return offset;
  }

  private byte[] longToBytes(long value) {
    byte[] bytes = new byte[8];
    bytes[0] = (byte) (value >> 56);
    bytes[1] = (byte) (value >> 48);
    bytes[2] = (byte) (value >> 40);
    bytes[3] = (byte) (value >> 32);
    bytes[4] = (byte) (value >> 24);
    bytes[5] = (byte) (value >> 16);
    bytes[6] = (byte) (value >> 8);
    bytes[7] = (byte) value;
    return bytes;
  }
}
