package com.typeobject.wheeler.core.instruction.handlers;

import com.typeobject.wheeler.core.instruction.Instruction;
import com.typeobject.wheeler.core.instruction.InstructionHandler;
import com.typeobject.wheeler.core.thread.WheelerThread;

public class IncrementHandler implements InstructionHandler {
  @Override
  public void executeForward(WheelerThread thread, Instruction inst) {
    long value = thread.getStack().pop();
    thread.getHistoryStack().push(value);
    thread.getStack().push(value + 1);
  }

  @Override
  public void executeReverse(WheelerThread thread, Instruction inst) {
    thread.getStack().pop();
    long oldValue = thread.getHistoryStack().pop();
    thread.getStack().push(oldValue);
  }
}
