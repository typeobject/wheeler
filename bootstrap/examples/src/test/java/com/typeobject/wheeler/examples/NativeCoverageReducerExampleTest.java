package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.TransitionObserver;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for the Wheeler-written transition coverage reducer. */
class NativeCoverageReducerExampleTest {
  @Test
  void wheelerAndStageZeroReduceTransitionsToIdenticalCanonicalBytes() throws Exception {
    Program subject = new WheelerCompiler().compile("""
        classical class CoverageSubject {
          state long value = 0;

          rev void step() {
            value += 2;
          }

          entry void main() {
            step();
            assert(value == 2);
            reverse step();
            assert(value == 0);
          }
        }
        """);
    SemanticCoverage stageZero = new SemanticCoverage();
    List<Row> rows = new ArrayList<>();
    TransitionObserver observer = observation -> {
      stageZero.observe(observation);
      rows.add(row(observation));
    };
    for (int run = 0; run < 2; run++) {
      VirtualMachine machine = new VirtualMachine(subject, observer);
      machine.run();
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
    }
    Collections.reverse(rows);

    Program reducer = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "CoverageReducer.w",
            Files.readString(Path.of(
                "../wheeler-runtime/src/main/wheeler/runtime/CoverageReducer.w"))),
        "wheeler.runtime.coverage_reducer");
    byte[] reduced = new WheelerRuntime()
        .executeBinaryInput(reducer, encode(rows), 32_768)
        .output();

    assertArrayEquals(
        stageZero.canonicalReport().getBytes(StandardCharsets.UTF_8),
        reduced);
  }

  private static Row row(TransitionObserver.Observation observation) {
    String direction = observation.direction().name().toLowerCase(Locale.ROOT);
    String branch = switch (observation.branchOutcome()) {
      case 0 -> "fallthrough";
      case 1 -> "taken";
      default -> "none";
    };
    String opcode = observation.opcode().name();
    String prefix = "{\"branch\":\"" + branch + "\"";
    String suffix = ",\"direction\":\"" + direction
        + "\",\"function\":" + observation.functionId()
        + ",\"instruction\":" + observation.instructionIndex()
        + ",\"opcode\":\"" + opcode + "\"}";
    ByteArrayOutputStream key = new ByteArrayOutputStream();
    key.writeBytes(direction.getBytes(StandardCharsets.US_ASCII));
    key.write(0);
    key.writeBytes(ByteBuffer.allocate(8)
        .order(ByteOrder.BIG_ENDIAN)
        .putInt(observation.functionId())
        .putInt(observation.instructionIndex())
        .array());
    key.writeBytes(opcode.getBytes(StandardCharsets.US_ASCII));
    key.write(0);
    key.writeBytes(branch.getBytes(StandardCharsets.US_ASCII));
    return new Row(
        key.toByteArray(),
        prefix.getBytes(StandardCharsets.UTF_8),
        suffix.getBytes(StandardCharsets.UTF_8));
  }

  private static byte[] encode(List<Row> rows) {
    if (rows.size() > 64) {
      throw new IllegalArgumentException("coverage fixture exceeds the Wheeler row bound");
    }
    ByteArrayOutputStream encoded = new ByteArrayOutputStream();
    encoded.write(rows.size());
    rows.forEach(row -> {
      writeField(encoded, row.key());
      writeField(encoded, row.prefix());
      writeField(encoded, row.suffix());
    });
    return encoded.toByteArray();
  }

  private static void writeField(ByteArrayOutputStream output, byte[] value) {
    if (value.length == 0 || value.length > 256) {
      throw new IllegalArgumentException("coverage row field is outside the Wheeler bound");
    }
    output.write(value.length & 0xff);
    output.write(value.length >>> 8);
    output.writeBytes(value);
  }

  private record Row(byte[] key, byte[] prefix, byte[] suffix) {
    private Row {
      key = key.clone();
      prefix = prefix.clone();
      suffix = suffix.clone();
    }
  }
}
