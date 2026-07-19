package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.List;

/** Binds exact externally owned entry effects to verified borrow parameters. */
final class HostEffectBinder {
  record Effects(List<Long> arguments, long outputHandle) {
    Effects {
      arguments = List.copyOf(arguments);
    }
  }

  private HostEffectBinder() {}

  static Effects bind(
      FunctionBody entry,
      OwnedStore store,
      byte[] hostInput,
      boolean binaryInput,
      int outputBytes) {
    boolean needsUtf8 = entry.parameterCount() > 0
        && entry.localType(0).equals(ValueType.UTF8_BORROW);
    boolean needsBytes = entry.parameterCount() > 0
        && entry.localType(0).equals(ValueType.BYTE_VIEW);
    boolean needsInput = needsUtf8 || needsBytes;
    boolean needsOutput = entry.parameterCount() > 0
        && entry.localType(entry.parameterCount() - 1).equals(ValueType.BYTES_BORROW);
    if (needsInput != (hostInput != null)) {
      throw new VmTrap(needsInput
          ? "Program requires one host input"
          : "Program does not declare a host input");
    }
    if (needsInput && binaryInput != needsBytes) {
      throw new VmTrap(needsBytes
          ? "Program requires binary byte input"
          : "Program requires strict UTF-8 input");
    }
    if (needsOutput != (outputBytes >= 0)) {
      throw new VmTrap(needsOutput
          ? "Program requires one host byte output"
          : "Program does not declare a host byte output");
    }

    List<Long> arguments = new ArrayList<>(entry.parameterCount());
    if (needsUtf8) {
      arguments.add(store.hostUtf8(hostInput));
    }
    if (needsBytes) {
      arguments.add(store.hostByteView(hostInput));
    }
    long outputHandle = needsOutput ? store.hostBytes(outputBytes) : 0;
    if (needsOutput) {
      arguments.add(outputHandle);
    }
    return new Effects(arguments, outputHandle);
  }
}
