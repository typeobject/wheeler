package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for linked aggregate and global section emission. */
final class NativeCompilerLinkedAggregateSectionsExampleTest {
  @Test
  void reproducesCanonicalAggregateSectionsFromProducts() throws Exception {
    byte[] artifact = artifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertArrayEquals(concatenatedSections(artifact, 3, 4), machine.hostOutput());
  }

  @Test
  void rejectsOutOfRangeAggregateNamesBeforePublication() throws Exception {
    byte[] artifact = artifact();
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int typeStart = sectionStart(artifact, 3);
    bytes.putInt(typeStart + 28, bytes.getInt(sectionStart(artifact, 2)));
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), artifact, 1_048_576);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static byte[] artifact() {
    String source = """
        module fixture.linked_aggregates;

        classical class LinkedAggregates {
          state long marker = -7;

          record Pair(long left, boolean ready) {}
          record Wrapper(Pair pair) {}

          variant Choice {
            case Empty();
            case Value(long item);
          }

          entry void main() {
            Pair pair = new Pair(4, true);
            long[3] values = new long[3](1, 2, 3);
            Choice choice = new Choice.Value(pair.left);
            assert(values[1] == 2);
            match (choice) {
              case Choice.Empty() {
                assert(false);
              }
              case Choice.Value(long item) {
                assert(item == 4);
              }
            }
          }
        }
        """;
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of("LinkedAggregates.w", source), "fixture.linked_aggregates");
    return new BytecodeWriter().write(program);
  }

  private static byte[] concatenatedSections(byte[] artifact, int... types) {
    int length = 0;
    for (int type : types) {
      length += sectionLength(artifact, type);
    }
    byte[] output = new byte[length];
    int cursor = 0;
    for (int type : types) {
      int start = sectionStart(artifact, type);
      int sectionLength = sectionLength(artifact, type);
      System.arraycopy(artifact, start, output, cursor, sectionLength);
      cursor += sectionLength;
    }
    return output;
  }

  private static int sectionStart(byte[] artifact, int type) {
    int directory = sectionDirectory(artifact, type);
    return Math.toIntExact(ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getLong(directory + 8));
  }

  private static int sectionLength(byte[] artifact, int type) {
    int directory = sectionDirectory(artifact, type);
    return Math.toIntExact(ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN)
        .getLong(directory + 16));
  }

  private static int sectionDirectory(byte[] artifact, int type) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int count = bytes.getInt(24);
    for (int index = 0; index < count; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == type) {
        return directory;
      }
    }
    throw new AssertionError("missing section " + type);
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_global_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_string_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_aggregate_sections"));
    sources.put("LinkedAggregateSectionsExample.w", """
        module example.linked_aggregate_sections;

        import wheeler.compiler.closure.compiled_global_products;
        import wheeler.compiler.closure.compiled_string_products;
        import wheeler.compiler.closure.counted_aggregate_layouts;
        import wheeler.compiler.closure.linked_aggregate_sections;

        classical class LinkedAggregateSectionsExample {
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 1810432, /* allocations= */ 11);
            words processed = allocate(rows, /* length= */ 512);
            words aggregates = allocate(rows, /* length= */ 36864);
            words cases = allocate(rows, /* length= */ 32768);
            words members = allocate(rows, /* length= */ 65536);
            words artifactRanks = allocate(rows, /* length= */ 16384);
            words stringStarts = allocate(rows, /* length= */ 16384);
            words stringLengths = allocate(rows, /* length= */ 16384);
            words finalStrings = allocate(rows, /* length= */ 16384);
            words moduleStringBases = allocate(rows, /* length= */ 512);
            words finalDescriptors = allocate(rows, /* length= */ 4096);
            words globals = allocate(rows, /* length= */ 20480);
            CountedAggregateLayoutPlan aggregatePlan = appendCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 0,
              /* moduleCount= */ 0,
              /* aggregateCount= */ 0,
              /* caseCount= */ 0,
              /* memberCount= */ 0,
              processed,
              aggregates,
              cases,
              members
            );
            CompiledStringPlan stringPlan = appendCompiledStringProducts(
              source,
              bufferLength(source),
              /* artifactBase= */ 0,
              /* artifactRank= */ 0,
              /* closureStringCount= */ 0,
              artifactRanks,
              stringStarts,
              stringLengths
            );
            set(moduleStringBases, 0, 0);
            long globalCount = appendCompiledGlobalProducts(
              source,
              bufferLength(source),
              /* moduleOwner= */ 0,
              /* moduleStringBase= */ 0,
              stringPlan.stringCount,
              /* closureGlobalCount= */ 0,
              globals
            );
            long string = 0;
            while (string < stringPlan.stringCount) limit 16384 {
              set(finalStrings, string, string);
              string += 1;
            }
            long records = 0;
            long arrays = 0;
            long slices = 0;
            long variants = 0;
            long aggregate = 0;
            while (aggregate < aggregatePlan.aggregateCount) limit 4096 {
              long kind = aggregates[aggregate];
              if (kind == 1) {
                set(finalDescriptors, aggregate, records);
                records += 1;
              } else {
                if (kind == 2) {
                  set(finalDescriptors, aggregate, arrays);
                  arrays += 1;
                } else {
                  if (kind == 3) {
                    set(finalDescriptors, aggregate, slices);
                    slices += 1;
                  } else {
                    assert(kind == 4);
                    set(finalDescriptors, aggregate, variants);
                    variants += 1;
                  }
                }
              }
              aggregate += 1;
            }
            long typeBytes = emitLinkedTypeSection(
              globalCount,
              globals,
              aggregatePlan.aggregateCount,
              stringPlan.closureStringCount,
              moduleStringBases,
              finalStrings,
              aggregates,
              members,
              finalDescriptors,
              output,
              /* outputStart= */ 0
            );
            long variantBytes = emitLinkedVariantSection(
              aggregatePlan.aggregateCount,
              aggregatePlan.caseCount,
              stringPlan.closureStringCount,
              moduleStringBases,
              finalStrings,
              aggregates,
              cases,
              members,
              finalDescriptors,
              output,
              /* outputStart= */ typeBytes
            );
            published = 1;
            setOutputLength(output, typeBytes + variantBytes);
            drop(globals);
            drop(finalDescriptors);
            drop(moduleStringBases);
            drop(finalStrings);
            drop(stringLengths);
            drop(stringStarts);
            drop(artifactRanks);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(processed);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.linked_aggregate_sections");
  }
}
