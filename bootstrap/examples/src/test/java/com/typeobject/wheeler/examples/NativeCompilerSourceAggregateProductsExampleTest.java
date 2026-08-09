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
        "wheeler.compiler.closure.source_aggregate_products"));
    sources.put("SourceAggregateProductsExample.w", """
        module example.source_aggregate_products;

        import wheeler.compiler.closure.source_aggregate_layouts;
        import wheeler.compiler.closure.source_aggregate_products;

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

          entry void main(borrow utf8 input) {
            region rows = new region(/* bytes= */ 64512, /* allocations= */ 8);
            words aggregates = allocate(rows, /* length= */ 832);
            words cases = allocate(rows, /* length= */ 640);
            words members = allocate(rows, /* length= */ 2048);
            words projectedAggregates = allocate(rows, /* length= */ 832);
            words projectedCases = allocate(rows, /* length= */ 640);
            words projectedMembers = allocate(rows, /* length= */ 2048);
            words stringStarts = allocate(rows, /* length= */ 512);
            words stringLengths = allocate(rows, /* length= */ 512);
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
