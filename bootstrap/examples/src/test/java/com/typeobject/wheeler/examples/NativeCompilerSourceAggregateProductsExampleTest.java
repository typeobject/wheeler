package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-local aggregate products. */
final class NativeCompilerSourceAggregateProductsExampleTest {
  @Test
  void publishesRecursiveRecordProductsWithoutCompiledArtifacts() throws Exception {
    String source = """
        classical class Root {
          public record Node(long value, Maybe next, long[4] values) {}
          public variant Maybe {
            case End();
            case More(Node node);
          }
          private record Pair(boolean ready, Node node) {}
        }
        """;
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("productValid"));
    assertEquals(4, machine.global("aggregateCount"));
    assertEquals(2, machine.global("caseCount"));
    assertEquals(6, machine.global("memberCount"));
    assertEquals(source.indexOf("Node"), machine.global("firstNameStart"));
    assertEquals(source.indexOf("variant Maybe") + 8, machine.global("secondNameStart"));
    assertEquals(source.indexOf("Pair"), machine.global("thirdNameStart"));
    assertEquals(1, machine.global("firstKind"));
    assertEquals(4, machine.global("secondKind"));
    assertEquals(2, machine.global("fourthKind"));
    assertEquals(1, machine.global("arrayElement"));
    assertEquals(4, machine.global("arrayLength"));
    assertEquals(0, machine.global("firstMember"));
    assertEquals(3, machine.global("secondMember"));
    assertEquals(4, machine.global("thirdMember"));
    assertEquals(3, machine.global("firstMemberCount"));
    assertEquals(1, machine.global("secondMemberCount"));
    assertEquals(2, machine.global("thirdMemberCount"));
    assertEquals(1, machine.global("firstVisibility"));
    assertEquals(1, machine.global("secondVisibility"));
    assertEquals(0, machine.global("thirdVisibility"));
    assertEquals(source.indexOf("long"), machine.global("firstTypeStart"));
    assertEquals(4, machine.global("firstTypeLength"));
    assertEquals(source.indexOf("boolean"), machine.global("fifthTypeStart"));
    assertEquals(7, machine.global("fifthTypeLength"));
    assertEquals(0, machine.global("firstTypeKind"));
    assertEquals(1, machine.global("firstTypeValue"));
    assertEquals(1, machine.global("secondTypeKind"));
    assertEquals(1, machine.global("secondTypeValue"));
    assertEquals(1, machine.global("thirdTypeKind"));
    assertEquals(3, machine.global("thirdTypeValue"));
    assertEquals(1, machine.global("fourthTypeKind"));
    assertEquals(0, machine.global("fourthTypeValue"));
    assertEquals(0, machine.global("fifthTypeKind"));
    assertEquals(2, machine.global("fifthTypeValue"));
    assertEquals(source.indexOf("End"), machine.global("firstCaseNameStart"));
    assertEquals(source.indexOf("More"), machine.global("secondCaseNameStart"));
    assertEquals(0, machine.global("firstCaseMemberCount"));
    assertEquals(1, machine.global("secondCaseMemberCount"));
    assertEquals(4, machine.global("projectedAggregateCount"));
    assertEquals(2, machine.global("projectedCaseCount"));
    assertEquals(7, machine.global("projectedMemberCount"));
    assertEquals(12, machine.global("projectedStringCount"));
    assertEquals(0, machine.global("firstProjectedTypeId"));
    assertEquals(0, machine.global("secondProjectedTypeId"));
    assertEquals(1, machine.global("thirdProjectedTypeId"));
    assertEquals(0, machine.global("fourthProjectedTypeId"));
    assertEquals(536_870_912, machine.global("secondProjectedMemberType"));
    assertEquals(805_306_368, machine.global("thirdProjectedMemberType"));
    assertEquals(1, machine.global("arrayProjectedMemberType"));
    assertEquals(1, machine.global("countedModuleCount"));
    assertEquals(4, machine.global("countedAggregateCount"));
    assertEquals(2, machine.global("countedCaseCount"));
    assertEquals(7, machine.global("countedMemberCount"));
    assertEquals(1, machine.global("countedArrayMemberType"));
    assertEquals(12, machine.global("archivedStringCount"));
    assertEquals(55, machine.global("archivedStringBytes"));
    assertEquals(78, machine.global("firstArchivedByte"));
    assertEquals(4, machine.global("firstArchivedLength"));
    assertEquals(92, machine.global("linkedTypeBytes"));
    assertEquals(2, machine.global("linkedRecordCount"));
    assertEquals(1, machine.global("linkedFirstFieldType"));
    assertEquals(536_870_912, machine.global("linkedRecursiveFieldType"));
    assertEquals(805_306_368, machine.global("linkedArrayFieldType"));
    assertEquals(1, machine.global("linkedArrayElementType"));
    assertEquals(40, machine.global("linkedVariantBytes"));
    assertEquals(1, machine.global("linkedVariantCount"));
    assertEquals(2, machine.global("linkedVariantCaseCount"));
    assertEquals(268_435_456, machine.global("linkedVariantMemberType"));
  }

  @Test
  void leavesCallerRowsUntouchedWhenARecordMemberIsMalformed() throws Exception {
    String source = "classical class Root { public record Broken(long) {} }";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(73, machine.global("firstMemberOwner"));
    assertEquals(61, machine.global("firstCaseOwner"));
  }

  @Test
  void rejectsDuplicateVariantCasesBeforePublication() throws Exception {
    String source = """
        classical class Root {
          public variant Broken { case Same(); case Same(); }
        }
        """;
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(61, machine.global("firstCaseOwner"));
  }

  @Test
  void rejectsNonescapingSliceMembersBeforePublication() throws Exception {
    String source = "classical class Root { public record Broken(long[] values) {} }";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(73, machine.global("firstMemberOwner"));
  }

  @Test
  void rejectsUnresolvedMemberTypesBeforePublication() throws Exception {
    String source = "classical class Root { public record Broken(Missing value) {} }";
    VirtualMachine machine = machine(source);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("productValid"));
    assertEquals(91, machine.global("firstNameStart"));
    assertEquals(73, machine.global("firstMemberOwner"));
    assertEquals(61, machine.global("firstCaseOwner"));
  }

  private static VirtualMachine machine(String source) throws Exception {
    return new VirtualMachine(program(), source.getBytes(StandardCharsets.UTF_8));
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_aggregate_layouts"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_aggregate_sections"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_string_section"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_aggregate_products"));
    sources.put("SourceAggregateProductsExample.w", """
        module example.source_aggregate_products;

        import wheeler.compiler.closure.counted_aggregate_layouts;
        import wheeler.compiler.closure.linked_aggregate_sections;
        import wheeler.compiler.closure.linked_string_section;
        import wheeler.compiler.closure.source_aggregate_layouts;
        import wheeler.compiler.closure.source_aggregate_products;
        import wheeler.compiler.closure.source_aggregate_strings;
        import wheeler.core.encoding.binary;

        classical class SourceAggregateProductsExample {
          state long productValid = 0;
          state long aggregateCount = 0;
          state long caseCount = 0;
          state long memberCount = 0;
          state long firstNameStart = 0;
          state long secondNameStart = 0;
          state long thirdNameStart = 0;
          state long firstKind = 0;
          state long secondKind = 0;
          state long fourthKind = 0;
          state long arrayElement = 0;
          state long arrayLength = 0;
          state long firstMember = 0;
          state long secondMember = 0;
          state long thirdMember = 0;
          state long firstMemberCount = 0;
          state long secondMemberCount = 0;
          state long thirdMemberCount = 0;
          state long firstVisibility = 0;
          state long secondVisibility = 0;
          state long thirdVisibility = 0;
          state long firstTypeStart = 0;
          state long firstTypeLength = 0;
          state long fifthTypeStart = 0;
          state long fifthTypeLength = 0;
          state long firstMemberOwner = 0;
          state long firstCaseOwner = 0;
          state long firstTypeKind = 0;
          state long firstTypeValue = 0;
          state long secondTypeKind = 0;
          state long secondTypeValue = 0;
          state long thirdTypeKind = 0;
          state long thirdTypeValue = 0;
          state long fourthTypeKind = 0;
          state long fourthTypeValue = 0;
          state long fifthTypeKind = 0;
          state long fifthTypeValue = 0;
          state long firstCaseNameStart = 0;
          state long secondCaseNameStart = 0;
          state long firstCaseMemberCount = 0;
          state long secondCaseMemberCount = 0;
          state long projectedAggregateCount = 0;
          state long projectedCaseCount = 0;
          state long projectedMemberCount = 0;
          state long projectedStringCount = 0;
          state long firstProjectedTypeId = 0;
          state long secondProjectedTypeId = 0;
          state long thirdProjectedTypeId = 0;
          state long fourthProjectedTypeId = 0;
          state long secondProjectedMemberType = 0;
          state long thirdProjectedMemberType = 0;
          state long arrayProjectedMemberType = 0;
          state long countedModuleCount = 0;
          state long countedAggregateCount = 0;
          state long countedCaseCount = 0;
          state long countedMemberCount = 0;
          state long countedArrayMemberType = 0;
          state long archivedStringCount = 0;
          state long archivedStringBytes = 0;
          state long firstArchivedByte = 0;
          state long firstArchivedLength = 0;
          state long linkedTypeBytes = 0;
          state long linkedRecordCount = 0;
          state long linkedFirstFieldType = 0;
          state long linkedRecursiveFieldType = 0;
          state long linkedArrayFieldType = 0;
          state long linkedArrayElementType = 0;
          state long linkedVariantBytes = 0;
          state long linkedVariantCount = 0;
          state long linkedVariantCaseCount = 0;
          state long linkedVariantMemberType = 0;

          entry void main(borrow utf8 input) {
            region rows = new region(/* bytes= */ 1883392, /* allocations= */ 22);
            words aggregates = allocate(rows, /* length= */ 832);
            words cases = allocate(rows, /* length= */ 640);
            words members = allocate(rows, /* length= */ 2048);
            words projectedAggregates = allocate(rows, /* length= */ 832);
            words projectedCases = allocate(rows, /* length= */ 640);
            words projectedMembers = allocate(rows, /* length= */ 2048);
            words stringStarts = allocate(rows, /* length= */ 512);
            words stringLengths = allocate(rows, /* length= */ 512);
            words processedModules = allocate(rows, /* length= */ 512);
            words closureAggregates = allocate(rows, /* length= */ 36864);
            words closureCases = allocate(rows, /* length= */ 32768);
            words closureMembers = allocate(rows, /* length= */ 65536);
            bytes aggregateStringArchive = allocateBytes(rows, /* length= */ 4096);
            words stringArtifactRanks = allocate(rows, /* length= */ 16384);
            words archivedStringStarts = allocate(rows, /* length= */ 16384);
            words archivedStringLengths = allocate(rows, /* length= */ 16384);
            words finalStrings = allocate(rows, /* length= */ 16384);
            words moduleStringBases = allocate(rows, /* length= */ 512);
            words finalDescriptors = allocate(rows, /* length= */ 4096);
            words globals = allocate(rows, /* length= */ 20480);
            bytes linkedStrings = allocateBytes(rows, /* length= */ 4096);
            bytes linkedSections = allocateBytes(rows, /* length= */ 256);
            set(aggregates, 64, 91);
            set(cases, 0, 61);
            set(members, 0, 73);
            SourceAggregateProductPlan product = materializeSourceAggregateProducts(
              input,
              aggregates,
              cases,
              members
            );
            if (product.valid) {
              ProjectedSourceAggregatePlan projected = projectSourceAggregateLayouts(
                input,
                /* moduleOwner= */ 7,
                product.aggregateCount,
                product.caseCount,
                product.memberCount,
                aggregates,
                cases,
                members,
                projectedAggregates,
                projectedCases,
                projectedMembers,
                stringStarts,
                stringLengths
              );
              projectedAggregateCount = projected.aggregateCount;
              projectedCaseCount = projected.caseCount;
              projectedMemberCount = projected.memberCount;
              projectedStringCount = projected.stringCount;
              firstProjectedTypeId = projectedAggregates[128];
              secondProjectedTypeId = projectedAggregates[129];
              thirdProjectedTypeId = projectedAggregates[130];
              fourthProjectedTypeId = projectedAggregates[131];
              secondProjectedMemberType = projectedMembers[769];
              thirdProjectedMemberType = projectedMembers[770];
              arrayProjectedMemberType = projectedMembers[774];
              SourceAggregateStringPlan archivedStrings = appendSourceAggregateStrings(
                input,
                /* artifactRank= */ 2,
                projected.stringCount,
                stringStarts,
                stringLengths,
                /* archiveBytes= */ 0,
                /* closureStringCount= */ 0,
                aggregateStringArchive,
                stringArtifactRanks,
                archivedStringStarts,
                archivedStringLengths
              );
              archivedStringCount = archivedStrings.stringCount;
              archivedStringBytes = archivedStrings.archiveBytes;
              firstArchivedByte = aggregateStringArchive[0];
              firstArchivedLength = archivedStringLengths[0];
              CountedAggregateLayoutPlan counted = appendProjectedAggregateLayouts(
                /* owner= */ 7,
                /* moduleCount= */ 0,
                /* aggregateCount= */ 0,
                /* caseCount= */ 0,
                /* memberCount= */ 0,
                projected.aggregateCount,
                projected.caseCount,
                projected.memberCount,
                projectedAggregates,
                projectedCases,
                projectedMembers,
                processedModules,
                closureAggregates,
                closureCases,
                closureMembers
              );
              countedModuleCount = counted.moduleCount;
              countedAggregateCount = counted.aggregateCount;
              countedCaseCount = counted.caseCount;
              countedMemberCount = counted.memberCount;
              countedArrayMemberType = closureMembers[49158];
              long linkedStringBytes = emitLinkedStringSectionAt(
                aggregateStringArchive,
                archivedStrings.archiveBytes,
                archivedStrings.stringCount,
                archivedStringStarts,
                archivedStringLengths,
                finalStrings,
                linkedStrings,
                /* outputStart= */ 0
              );
              assert(0 < linkedStringBytes);
              set(moduleStringBases, 0, 0);
              set(finalDescriptors, 0, 0);
              set(finalDescriptors, 1, 0);
              set(finalDescriptors, 2, 1);
              set(finalDescriptors, 3, 0);
              linkedTypeBytes = emitLinkedTypeSection(
                /* globalCount= */ 0,
                globals,
                counted.aggregateCount,
                archivedStrings.stringCount,
                moduleStringBases,
                finalStrings,
                closureAggregates,
                closureMembers,
                finalDescriptors,
                linkedSections,
                /* outputStart= */ 0
              );
              linkedRecordCount = readUnsigned(linkedSections, 4, 4);
              linkedFirstFieldType = readUnsigned(linkedSections, 24, 4);
              linkedRecursiveFieldType = readUnsigned(linkedSections, 32, 4);
              linkedArrayFieldType = readUnsigned(linkedSections, 40, 4);
              linkedArrayElementType = readUnsigned(linkedSections, 80, 4);
              linkedVariantBytes = emitLinkedVariantSection(
                counted.aggregateCount,
                counted.caseCount,
                archivedStrings.stringCount,
                moduleStringBases,
                finalStrings,
                closureAggregates,
                closureCases,
                closureMembers,
                finalDescriptors,
                linkedSections,
                /* outputStart= */ 128
              );
              linkedVariantCount = readUnsigned(linkedSections, 128, 4);
              linkedVariantCaseCount = readUnsigned(linkedSections, 140, 4);
              linkedVariantMemberType = readUnsigned(linkedSections, 164, 4);
              productValid = 1;
            }
            aggregateCount = product.aggregateCount;
            caseCount = product.caseCount;
            memberCount = product.memberCount;
            firstKind = aggregates[0];
            secondKind = aggregates[1];
            fourthKind = aggregates[3];
            arrayElement = aggregates[643];
            arrayLength = aggregates[707];
            firstNameStart = aggregates[64];
            secondNameStart = aggregates[65];
            thirdNameStart = aggregates[66];
            firstMember = aggregates[320];
            secondMember = aggregates[321];
            thirdMember = aggregates[322];
            firstMemberCount = aggregates[384];
            secondMemberCount = aggregates[385];
            thirdMemberCount = aggregates[386];
            firstVisibility = aggregates[448];
            secondVisibility = aggregates[449];
            thirdVisibility = aggregates[450];
            firstTypeStart = members[1024];
            firstTypeLength = members[1280];
            fifthTypeStart = members[1028];
            fifthTypeLength = members[1284];
            firstMemberOwner = members[0];
            firstCaseOwner = cases[0];
            firstTypeKind = members[1536];
            firstTypeValue = members[1792];
            secondTypeKind = members[1537];
            secondTypeValue = members[1793];
            thirdTypeKind = members[1538];
            thirdTypeValue = members[1794];
            fourthTypeKind = members[1539];
            fourthTypeValue = members[1795];
            fifthTypeKind = members[1540];
            fifthTypeValue = members[1796];
            firstCaseNameStart = cases[128];
            secondCaseNameStart = cases[129];
            firstCaseMemberCount = cases[512];
            secondCaseMemberCount = cases[513];
            drop(linkedSections);
            drop(linkedStrings);
            drop(globals);
            drop(finalDescriptors);
            drop(moduleStringBases);
            drop(finalStrings);
            drop(archivedStringLengths);
            drop(archivedStringStarts);
            drop(stringArtifactRanks);
            drop(aggregateStringArchive);
            drop(closureMembers);
            drop(closureCases);
            drop(closureAggregates);
            drop(processedModules);
            drop(stringLengths);
            drop(stringStarts);
            drop(projectedMembers);
            drop(projectedCases);
            drop(projectedAggregates);
            drop(members);
            drop(cases);
            drop(aggregates);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_aggregate_products");
  }
}
