// WheelerThread.java
package com.typeobject.wheeler.core.thread;

import com.typeobject.wheeler.core.instruction.Instruction;
import com.typeobject.wheeler.core.memory.MemoryManager;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;

public class WheelerThread {
  private final long id;
  private long pc;
  private final Deque<Long> stack;
  private final Deque<Long> historyStack;
  private final Map<Long, Long> localStorage;
  private WheelerThreadStatus status;
  private final MemoryManager memory;

  public WheelerThread(long id, MemoryManager memory) {
    this.id = id;
    this.pc = 0;
    this.stack = new ArrayDeque<>();
    this.historyStack = new ArrayDeque<>();
    this.localStorage = new HashMap<>();
    this.status = WheelerThreadStatus.RUNNING;
    this.memory = memory;
  }

  public long getId() {
    return id;
  }

  public long getPc() {
    return pc;
  }

  public Deque<Long> getStack() {
    return stack;
  }

  public Deque<Long> getHistoryStack() {
    return historyStack;
  }

  public Map<Long, Long> getLocalStorage() {
    return localStorage;
  }

  public WheelerThreadStatus getStatus() {
    return status;
  }

  public void setPc(long pc) {
    this.pc = pc;
  }

  public void setStatus(WheelerThreadStatus status) {
    this.status = status;
  }

  public Instruction fetchInstruction() {
    byte[] instructionBytes = new byte[Instruction.SIZE];
    for (int i = 0; i < Instruction.SIZE; i++) {
      instructionBytes[i] = (byte) (memory.readWord(pc + i/8) >> ((7 - i%8) * 8));
    }
    return Instruction.fromBytes(instructionBytes);
  }

  public void setState(WheelerThreadState state) {
    if (this.id != state.getId()) {
      throw new IllegalArgumentException("Thread ID mismatch");
    }

    this.pc = state.getPc();
    this.stack.clear();
    this.stack.addAll(state.getStack());
    this.historyStack.clear();
    this.historyStack.addAll(state.getHistoryStack());
    this.localStorage.clear();
    this.localStorage.putAll(state.getLocalStorage());
    this.status = state.getStatus();
  }

  public WheelerThreadState getState() {
    return new WheelerThreadState(this);
  }

  public boolean isTerminated() {
    return status == WheelerThreadStatus.TERMINATED;
  }

  public void advancePC() {
    pc += Instruction.SIZE;
  }
}