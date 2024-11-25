// InstructionHandler.java
package com.typeobject.wheeler.core.instruction;

import com.typeobject.wheeler.core.exceptions.InvalidInstructionException;
import com.typeobject.wheeler.core.thread.WheelerThread;

public interface InstructionHandler {
  void executeForward(WheelerThread thread, Instruction inst);
  void executeReverse(WheelerThread thread, Instruction inst);

  default void verify(Instruction inst) throws InvalidInstructionException {
    // Default implementation accepts all instructions
  }
}