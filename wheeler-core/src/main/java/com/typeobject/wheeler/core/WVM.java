// WVM.java
package com.typeobject.wheeler.core;

import com.typeobject.wheeler.core.history.ExecutionHistory;
import com.typeobject.wheeler.core.instruction.Instruction;
import com.typeobject.wheeler.core.instruction.InstructionHandler;
import com.typeobject.wheeler.core.instruction.InstructionSet;
import com.typeobject.wheeler.core.memory.MemoryManager;
import com.typeobject.wheeler.core.thread.WheelerThread;
import com.typeobject.wheeler.core.thread.WheelerThreadState;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class WVM {
  private final MemoryManager memory;
  private final Map<Long, WheelerThread> threads;
  private final ExecutionHistory history;

  public WVM() {
    this.memory = new MemoryManager();
    this.threads = new ConcurrentHashMap<>();
    this.history = new ExecutionHistory();
  }

  public void loadProgram(byte[] bytecode) {
    memory.load(bytecode);
  }

  public void execute() {
    WheelerThread mainThread = new WheelerThread(0, memory);
    threads.put(0L, mainThread);
    while (!mainThread.isTerminated()) {
      Instruction inst = mainThread.fetchInstruction();
      executeInstruction(mainThread, inst);
    }
  }

  private void executeInstruction(WheelerThread thread, Instruction inst) {
    InstructionHandler handler = InstructionSet.getHandler(inst.getOpcode());
    if (inst.isForward()) {
      history.recordState(thread.getId(), thread.getState());
      handler.executeForward(thread, inst);
    } else {
      WheelerThreadState state = history.getLastState(thread.getId());
      thread.setState(state);
      handler.executeReverse(thread, inst);
    }
  }
}