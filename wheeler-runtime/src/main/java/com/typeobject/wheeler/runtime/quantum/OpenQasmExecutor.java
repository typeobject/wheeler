package com.typeobject.wheeler.runtime.quantum;

import java.util.List;

/**
 * Provider hook for an OpenQASM 3 program.
 *
 * <p>Implementations may call a REST API, appliance SDK, queue, or local engine. They return one
 * canonical little-endian full-register outcome per requested shot.
 */
@FunctionalInterface
public interface OpenQasmExecutor {
  List<Long> execute(String openQasm, int shots, long seed) throws Exception;
}
