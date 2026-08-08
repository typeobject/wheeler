package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for counted semantic aggregate-layout products. */
final class NativeCompilerAggregateProductsExampleTest {
  @Test
  void decodesRecordArrayAndVariantLayoutsFromCanonicalBytecode() throws Exception {
    byte[] artifact = aggregateArtifact();
    Program decoder = decoder();
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder, artifact, 32);

    machine.run();

    assertEquals(4, machine.global("aggregateCount"));
    assertEquals(2, machine.global("caseCount"));
    assertEquals(5, machine.global("memberCount"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(1, machine.global("secondKind"));
    assertEquals(2, machine.global("thirdKind"));
    assertEquals(4, machine.global("lastKind"));
    assertEquals(3, machine.global("arrayLength"));
    assertEquals(1, machine.global("firstOwner"));
    assertEquals(2, machine.global("closureModuleCount"));
    assertEquals(8, machine.global("closureAggregateCount"));
    assertEquals(4, machine.global("closureCaseCount"));
    assertEquals(10, machine.global("closureMemberCount"));
    assertEquals(3, machine.global("secondModuleOwner"));
    assertEquals(2, machine.global("secondVariantFirstCase"));
    assertEquals(0, machine.global("finalFirstOwner"));
    assertEquals(2, machine.global("dependencyCount"));
    assertEquals(0, machine.global("wrapperTypeTarget"));
    assertEquals(32, machine.hostOutput().length);
    assertEquals(expectedIdentity(artifact), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsInvalidLayoutRowsBeforePublishingAnIdentity() throws Exception {
    byte[] artifact = aggregateArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(true), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals("00".repeat(32), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsEscapingOrUnbalancedLoansBeforePublishing() throws Exception {
    byte[] artifact = aggregateArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        decoder(false, true), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals("00".repeat(32), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsUnknownNominalMemberTypesBeforePublication() throws Exception {
    byte[] artifact = aggregateArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        decoder(false, false, false, true), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals("00".repeat(32), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsMissingExternalDependencyProductsBeforeIdentityPublication() throws Exception {
    byte[] artifact = aggregateArtifact();
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        decoder(false, false, true, false), artifact, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals("00".repeat(32), HexFormat.of().formatHex(machine.hostOutput()));
  }

  @Test
  void rejectsMalformedContainersBeforePublishingCounts() throws Exception {
    byte[] malformed = aggregateArtifact();
    malformed[0] = 0;
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), malformed, 32);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program decoder() throws Exception {
    return decoder(false, false, false, false);
  }

  private static Program decoder(boolean invalidLayout) throws Exception {
    return decoder(invalidLayout, false, false, false);
  }

  private static Program decoder(boolean invalidLayout, boolean invalidLoan) throws Exception {
    return decoder(invalidLayout, invalidLoan, false, false);
  }

  private static Program decoder(
      boolean invalidLayout,
      boolean invalidLoan,
      boolean invalidDependency,
      boolean invalidType) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_dependency_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_identities"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_loan_verifier"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_type_resolution"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_aggregate_layouts"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.put("AggregateProductsExample.w", """
        module example.aggregate_products;

        import wheeler.compiler.closure.aggregate_dependency_products;
        import wheeler.compiler.closure.aggregate_identities;
        import wheeler.compiler.closure.aggregate_loan_verifier;
        import wheeler.compiler.closure.aggregate_type_resolution;
        import wheeler.compiler.closure.compiled_aggregate_layouts;
        import wheeler.compiler.closure.counted_aggregate_layouts;

        classical class AggregateProductsExample {
          state long aggregateCount = 0;
          state long caseCount = 0;
          state long memberCount = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long thirdKind = 0;
          state long lastKind = 0;
          state long arrayLength = 0;
          state long firstOwner = 0;
          state long closureModuleCount = 0;
          state long closureAggregateCount = 0;
          state long closureCaseCount = 0;
          state long closureMemberCount = 0;
          state long secondModuleOwner = 0;
          state long secondVariantFirstCase = 0;
          state long finalFirstOwner = 1;
          state long dependencyCount = 0;
          state long wrapperTypeTarget = -1;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 19040, /* allocations= */ 7);
            words aggregates = allocate(rows, /* length= */ 576);
            words cases = allocate(rows, /* length= */ 512);
            words members = allocate(rows, /* length= */ 1024);
            bytes packageIdentity = allocateBytes(rows, /* length= */ 32);
            bytes moduleIdentity = allocateBytes(rows, /* length= */ 32);
            bytes aggregateIdentity = allocateBytes(rows, /* length= */ 32);
            bytes dependencyIdentities = allocateBytes(rows, /* length= */ 2048);
            long identityByte = 0;
            while (identityByte < 32) limit 32 {
              setByte(packageIdentity, identityByte, 1);
              setByte(moduleIdentity, identityByte, 2);
              identityByte += 1;
            }
            CompiledAggregatePlan plan = indexCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 1,
              aggregates,
              cases,
              members
            );
            INVALID_LAYOUT
            region dependencyProducts = new region(/* bytes= */ 55808, /* allocations= */ 7);
            words firstImports = allocate(dependencyProducts, /* length= */ 512);
            words directImports = allocate(dependencyProducts, /* length= */ 512);
            words edgeTargets = allocate(dependencyProducts, /* length= */ 3072);
            words localPublished = allocate(dependencyProducts, /* length= */ 512);
            words externalPublished = allocate(dependencyProducts, /* length= */ 64);
            bytes localIdentities = allocateBytes(dependencyProducts, /* length= */ 16384);
            bytes externalIdentities = allocateBytes(dependencyProducts, /* length= */ 2048);
            set(firstImports, 1, 0);
            set(directImports, 1, 2);
            set(edgeTargets, 0, 0);
            set(edgeTargets, 1, -1);
            set(localPublished, 0, 1);
            set(externalPublished, 0, 1);
            long dependencyIdentityByte = 0;
            while (dependencyIdentityByte < 32) limit 32 {
              setByte(localIdentities, dependencyIdentityByte, 4);
              setByte(externalIdentities, dependencyIdentityByte, 5);
              dependencyIdentityByte += 1;
            }
            INVALID_DEPENDENCY
            dependencyCount = packAggregateDependencyIdentities(
              /* moduleCount= */ 4,
              /* externalCount= */ 1,
              /* module= */ 1,
              firstImports,
              directImports,
              edgeTargets,
              localPublished,
              externalPublished,
              localIdentities,
              externalIdentities,
              dependencyIdentities
            );
            publishAggregateModuleIdentity(
              source,
              bufferLength(source),
              packageIdentity,
              moduleIdentity,
              dependencyCount,
              dependencyIdentities,
              /* owner= */ 1,
              plan.aggregateCount,
              plan.caseCount,
              plan.memberCount,
              aggregates,
              cases,
              members,
              aggregateIdentity
            );
            region closureRows = new region(/* bytes= */ 1085440, /* allocations= */ 4);
            words processed = allocate(closureRows, /* length= */ 512);
            words closureAggregates = allocate(closureRows, /* length= */ 36864);
            words closureCases = allocate(closureRows, /* length= */ 32768);
            words closureMembers = allocate(closureRows, /* length= */ 65536);
            CountedAggregateLayoutPlan firstClosure = appendCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 1,
              0,
              0,
              0,
              0,
              processed,
              closureAggregates,
              closureCases,
              closureMembers
            );
            CountedAggregateLayoutPlan secondClosure = appendCompiledAggregateLayouts(
              source,
              bufferLength(source),
              /* owner= */ 3,
              firstClosure.moduleCount,
              firstClosure.aggregateCount,
              firstClosure.caseCount,
              firstClosure.memberCount,
              processed,
              closureAggregates,
              closureCases,
              closureMembers
            );
            closureModuleCount = secondClosure.moduleCount;
            closureAggregateCount = secondClosure.aggregateCount;
            closureCaseCount = secondClosure.caseCount;
            closureMemberCount = secondClosure.memberCount;
            secondModuleOwner = closureAggregates[4096 + 4];
            secondVariantFirstCase = closureAggregates[16384 + 7];
            region ownershipRows = new region(/* bytes= */ 655360, /* allocations= */ 6);
            words initialOwned = allocate(ownershipRows, /* length= */ 4096);
            words events = allocate(ownershipRows, /* length= */ 49152);
            words finalOwned = allocate(ownershipRows, /* length= */ 4096);
            words finalShared = allocate(ownershipRows, /* length= */ 4096);
            words finalMutable = allocate(ownershipRows, /* length= */ 4096);
            words memberTypeTargets = allocate(ownershipRows, /* length= */ 16384);
            INVALID_TYPE
            resolveModuleAggregateMemberTypes(
              0,
              plan.aggregateCount,
              0,
              plan.memberCount,
              closureAggregates,
              closureMembers,
              memberTypeTargets
            );
            wrapperTypeTarget = memberTypeTargets[2];
            set(initialOwned, 0, 1);
            set(events, 0, 2);
            set(events, 1, 4);
            set(events, 2, 3);
            set(events, 3, 5);
            set(events, 4, 1);
            set(events, 32768 + 2, 1);
            INVALID_LOAN
            verifyAggregateProjectionEvents(
              secondClosure.aggregateCount,
              secondClosure.memberCount,
              closureAggregates,
              closureMembers,
              initialOwned,
              events,
              5,
              finalOwned,
              finalShared,
              finalMutable
            );
            finalFirstOwner = finalOwned[0];
            aggregateCount = plan.aggregateCount;
            caseCount = plan.caseCount;
            memberCount = plan.memberCount;
            firstKind = aggregates[0];
            secondKind = aggregates[1];
            thirdKind = aggregates[2];
            lastKind = aggregates[plan.aggregateCount - 1];
            arrayLength = aggregates[512 + 2];
            firstOwner = aggregates[64];
            long identityOutput = 0;
            while (identityOutput < 32) limit 32 {
              setByte(output, identityOutput, aggregateIdentity[identityOutput]);
              identityOutput += 1;
            }
            published = 1;
            setOutputLength(output, 32);
            drop(memberTypeTargets);
            drop(finalMutable);
            drop(finalShared);
            drop(finalOwned);
            drop(events);
            drop(initialOwned);
            drop(ownershipRows);
            drop(closureMembers);
            drop(closureCases);
            drop(closureAggregates);
            drop(processed);
            drop(closureRows);
            drop(externalIdentities);
            drop(localIdentities);
            drop(externalPublished);
            drop(localPublished);
            drop(edgeTargets);
            drop(directImports);
            drop(firstImports);
            drop(dependencyProducts);
            drop(dependencyIdentities);
            drop(aggregateIdentity);
            drop(moduleIdentity);
            drop(packageIdentity);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(rows);
          }
        }
        """.replace(
            "INVALID_LAYOUT",
            invalidLayout ? "set(aggregates, 0, 9);" : "").replace(
            "INVALID_LOAN",
            invalidLoan ? "set(events, 0, 4);" : "").replace(
            "INVALID_DEPENDENCY",
            invalidDependency ? "set(externalPublished, 0, 0);" : "").replace(
            "INVALID_TYPE",
            invalidType ? "set(closureMembers, 49152 + 2, 268436455);" : ""));
    return new WheelerCompiler().compileModuleFiles(sources, "example.aggregate_products");
  }

  private static String expectedIdentity(byte[] artifact) throws Exception {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    ByteBuffer types = section(bytes, 3);
    ByteBuffer variants = section(bytes, 4);
    List<long[]> aggregates = new ArrayList<>();
    List<long[]> cases = new ArrayList<>();
    List<long[]> members = new ArrayList<>();

    int globals = types.getInt();
    types.position(types.position() + globals * 16);
    int records = types.getInt();
    for (int record = 0; record < records; record++) {
      long typeId = Integer.toUnsignedLong(types.getInt());
      long name = Integer.toUnsignedLong(types.getInt());
      int fields = types.getInt();
      int firstMember = members.size();
      aggregates.add(new long[] {1, typeId, name, 0, 0, firstMember, fields, 0});
      int aggregate = aggregates.size() - 1;
      for (int field = 0; field < fields; field++) {
        members.add(new long[] {
            aggregate, -1, Integer.toUnsignedLong(types.getInt()),
            Integer.toUnsignedLong(types.getInt())});
      }
    }
    int arrays = types.getInt();
    for (int array = 0; array < arrays; array++) {
      long typeId = Integer.toUnsignedLong(types.getInt());
      long elementType = Integer.toUnsignedLong(types.getInt());
      long length = Integer.toUnsignedLong(types.getInt());
      int firstMember = members.size();
      aggregates.add(new long[] {2, typeId, -1, 0, 0, firstMember, 1, length});
      members.add(new long[] {aggregates.size() - 1, -1, -1, elementType});
    }
    int slices = types.getInt();
    for (int slice = 0; slice < slices; slice++) {
      long typeId = Integer.toUnsignedLong(types.getInt());
      long elementType = Integer.toUnsignedLong(types.getInt());
      int firstMember = members.size();
      aggregates.add(new long[] {3, typeId, -1, 0, 0, firstMember, 1, -1});
      members.add(new long[] {aggregates.size() - 1, -1, -1, elementType});
    }

    int variantCount = variants.getInt();
    for (int variant = 0; variant < variantCount; variant++) {
      long typeId = Integer.toUnsignedLong(variants.getInt());
      long name = Integer.toUnsignedLong(variants.getInt());
      int caseCount = variants.getInt();
      int aggregate = aggregates.size();
      int firstCase = cases.size();
      int firstMember = members.size();
      for (int nextCase = 0; nextCase < caseCount; nextCase++) {
        long caseName = Integer.toUnsignedLong(variants.getInt());
        int fields = variants.getInt();
        int caseIndex = cases.size();
        cases.add(new long[] {aggregate, caseName, members.size(), fields});
        for (int field = 0; field < fields; field++) {
          members.add(new long[] {
              aggregate, caseIndex, Integer.toUnsignedLong(variants.getInt()),
              Integer.toUnsignedLong(variants.getInt())});
        }
      }
      aggregates.add(new long[] {
          4, typeId, name, firstCase, caseCount, firstMember,
          members.size() - firstMember, 0});
    }

    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes("wheeler-aggregate-module-product-1".getBytes(StandardCharsets.US_ASCII));
    byte[] packageIdentity = new byte[32];
    java.util.Arrays.fill(packageIdentity, (byte) 1);
    input.writeBytes(packageIdentity);
    byte[] moduleIdentity = new byte[32];
    java.util.Arrays.fill(moduleIdentity, (byte) 2);
    input.writeBytes(moduleIdentity);
    input.writeBytes(MessageDigest.getInstance("SHA-256").digest(artifact));
    writeLong(input, 2);
    byte[] dependencyIdentity = new byte[32];
    java.util.Arrays.fill(dependencyIdentity, (byte) 4);
    input.writeBytes(dependencyIdentity);
    java.util.Arrays.fill(dependencyIdentity, (byte) 5);
    input.writeBytes(dependencyIdentity);
    writeLong(input, aggregates.size());
    writeLong(input, cases.size());
    writeLong(input, members.size());
    aggregates.forEach(row -> writeRow(input, row));
    cases.forEach(row -> writeRow(input, row));
    members.forEach(row -> writeRow(input, row));
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(input.toByteArray()));
  }

  private static ByteBuffer section(ByteBuffer artifact, int wantedType) {
    int sections = artifact.getInt(24);
    for (int index = 0; index < sections; index++) {
      int directory = 40 + index * 32;
      if (artifact.getInt(directory) == wantedType) {
        int start = Math.toIntExact(artifact.getLong(directory + 8));
        int length = Math.toIntExact(artifact.getLong(directory + 16));
        return artifact.slice(start, length).order(ByteOrder.LITTLE_ENDIAN);
      }
    }
    throw new AssertionError("missing section " + wantedType);
  }

  private static void writeRow(ByteArrayOutputStream output, long[] row) {
    for (long value : row) {
      writeLong(output, value);
    }
  }

  private static void writeLong(ByteArrayOutputStream output, long value) {
    for (int octet = 0; octet < 8; octet++) {
      output.write((int) (value >>> (octet * 8)) & 0xff);
    }
  }

  private static byte[] aggregateArtifact() {
    String source = """
        module fixture.aggregate_products;

        classical class AggregateProducts {
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
        Map.of("AggregateProducts.w", source),
        "fixture.aggregate_products");
    return new BytecodeWriter().write(program);
  }
}
