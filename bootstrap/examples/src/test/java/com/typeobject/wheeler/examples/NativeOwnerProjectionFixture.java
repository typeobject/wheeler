package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

/** Compares complete owner-event tables and output storage, then rewinds the entire fixture. */
final class NativeOwnerProjectionFixture {
  record Event(long kind, long function, long destination, long source) {}
  record Projection(long function, long local, long aggregate, long member) {}

  static final class Input {
    final List<Event> events = new ArrayList<>();
    final List<Projection> projections = new ArrayList<>();
    final int[] capacities = {40960, 65536, 16384};
    Long eventCount;
    Long projectionCount;
    boolean lastProjection;

    Input event(long kind, long function, long destination, long source) {
      events.add(new Event(kind, function, destination, source));
      return this;
    }

    Input projection(long function, long local, long aggregate, long member) {
      projections.add(new Projection(function, local, aggregate, member));
      return this;
    }
  }

  private NativeOwnerProjectionFixture() {}

  static void check(Input input, boolean valid) throws Exception {
    run(input, valid, false);
  }

  static void traps(Input input) throws Exception {
    run(input, false, true);
  }

  private static void run(Input input, boolean valid, boolean trap) throws Exception {
    StringBuilder setup = new StringBuilder();
    for (int row = 0; row < input.events.size(); row++) {
      Event event = input.events.get(row);
      setup.append("""
          set(events, %d, %d);
          set(events, %d, %d);
          set(events, %d, %d);
          set(events, %d, %d);
          """.formatted(row, event.kind(), 16384 + row, event.function(),
              24576 + row, event.destination(), 32768 + row, event.source()));
    }
    for (int row = 0; row < input.projections.size(); row++) {
      Projection projection = input.projections.get(row);
      int targetRow = input.lastProjection && row + 1 == input.projections.size() ? 16383 : row;
      setup.append("""
          set(projections, %d, %d);
          set(projections, %d, %d);
          set(projections, %d, %d);
          set(projections, %d, %d);
          """.formatted(targetRow, projection.function(), 16384 + targetRow, projection.local(),
              32768 + targetRow, projection.aggregate(), 49152 + targetRow, projection.member()));
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.frame_local_projections"));
    sources.put("OwnerProjectionProbe.w", """
        module example.owner_projection_probe;
        import wheeler.compiler.closure.frame_local_projections;
        classical class OwnerProjectionProbe {
          state long prepared = 0;
          state long finished = 0;
          state long valid = -1;
          state long count = -1;
          entry void main() {
            region caller = new region(/* bytes= */ 983064, /* allocations= */ 3);
            words events = allocate(caller, %d);
            words projections = allocate(caller, %d);
            words output = allocate(caller, %d);
            // Sparse canaries, with whole-table comparisons in Java.
            set(events, bufferLength(events) - 1, 71);
            set(projections, bufferLength(projections) - 1, 83);
            set(output, 0, 97);
            set(output, 8192, 101);
            set(output, bufferLength(output) - 1, 103);
            %s
            prepared = 1;
            AggregateOwnerProjectionPlan result = projectInstructionOwnerEvents(
              %d, events, %d, projections, output
            );
            valid = 0;
            if (result.valid) { valid = 1; }
            count = result.eventCount;
            finished = 1;
            drop(output);
            drop(projections);
            drop(events);
            drop(caller);
          }
        }
        """.formatted(input.capacities[0], input.capacities[1], input.capacities[2], setup,
            input.eventCount == null ? input.events.size() : input.eventCount,
            input.projectionCount == null ? input.projections.size() : input.projectionCount));
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.owner_projection_probe");
    var machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    var before = machine.snapshot();
    var expected = before.buffers().getLast().elements().stream()
        .mapToLong(Long::longValue).toArray();
    if (valid) {
      for (int row = 0; row < input.events.size(); row++) {
        Event event = input.events.get(row);
        long owner = event.kind() == 5 ? event.destination() : event.source();
        var matches = input.projections.stream().filter(p -> p.function() == event.function()
            && p.local() == owner).toList();
        assertEquals(1, matches.size());
        expected[row] = matches.getFirst().aggregate();
        expected[8192 + row] = matches.getFirst().member();
      }
    }
    if (trap) {
      assertThrows(VmTrap.class, () -> {
        while (machine.global("finished") == 0) { machine.step(); }
      });
      assertEquals(-1, machine.global("valid"));
    } else {
      while (machine.global("finished") == 0) { machine.step(); }
      assertEquals(valid ? 1 : 0, machine.global("valid"));
      assertEquals(input.events.size(), machine.global("count"));
    }
    var after = machine.snapshot();
    assertEquals(before.buffers().subList(0, 2), after.buffers().subList(0, 2));
    assertArrayEquals(expected, after.buffers().get(2).elements().stream()
        .mapToLong(Long::longValue).toArray());
    assertEquals(before.regions().getFirst(), after.regions().getFirst());
    if (trap) {
      assertEquals(before.buffers(), after.buffers());
      assertEquals(before.regions(), after.regions());
    } else { machine.run(); }
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }
}
