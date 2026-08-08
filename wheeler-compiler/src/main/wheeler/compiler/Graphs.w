//! Resolves bounded constant module graphs before canonical lowering.

module wheeler.compiler.compiler_graphs;

import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graph_five;
import wheeler.compiler.compiler_graph_four;
import wheeler.compiler.compiler_graph_seven;
import wheeler.compiler.compiler_graph_six;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.direct.mixed_three;
import wheeler.compiler.graphs.direct.mixed_two;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.plan_sources;
import wheeler.compiler.graphs.shared.three_direct_leaf;
import wheeler.compiler.graphs.small_plan_sources;
import wheeler.compiler.graphs.small_structures;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.graphs.two_redundant;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;
import wheeler.compiler.multiple_imported_helpers;

classical class CompilerGraphs {
  /// Carries private graph-compilation bounds across the driver boundary.
  public record GraphCompilation(long length, long codeStart) {}

  private GraphCompilation compileGraphSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  private GraphCompilation compileGraphSourceWithHelperImport(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan plan
  ) {
    HelperOwner imported = importedHelperOwner(
      plan.linkedOwnerStart,
      plan.linkedOwnerLength,
      plan.importedHelperCount
    );
    CoreCompilation compiled = compileMinimalCoreWithHelperOwners(
      source,
      output,
      oneHelperOwner(imported)
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with one direct scalar-constant or scalar-helper module.
  public GraphCompilation compileGraphWithConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, /* expectedImportCount= */ 1);
    boolean importedHelpers = false;
    if (plan.valid) {} else {
      plan = planResolvedHelperImport(importedSource, rootSource, /* expectedImportCount= */ 1);
      importedHelpers = plan.valid;
    }

    if (plan.valid) {} else {
      assert(0 == 1);
    }

    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    GraphCompilation compiled = new GraphCompilation(0, 0);
    if (importedHelpers) {
      compiled = compileGraphSourceWithHelperImport(linkedSource, output, plan);
    } else {
      compiled = compileGraphSource(linkedSource, output);
    }

    drop(linkedSource);
    drop(linkedArena);
    return compiled;
  }

  private GraphCompilation compileConstantChain(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      assert(0 == 1);
    }

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    boolean importedHelpers = false;
    if (rootPlan.valid) {} else {
      rootPlan = planResolvedHelperImport(
        linkedDependentSource,
        rootSource,
        /* expectedImportCount= */ 1
      );
      importedHelpers = rootPlan.valid;
    }

    if (rootPlan.valid) {} else {
      assert(0 == 1);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = new GraphCompilation(0, 0);
    if (importedHelpers) {
      compiled = compileGraphSourceWithHelperImport(linkedRootSource, output, rootPlan);
    } else {
      compiled = compileGraphSource(linkedRootSource, output);
    }

    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  private GraphCompilation compileTwoDirectImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    MixedTwoCompilation mixed = compileMixedTwoDirectGraph(
      firstImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return new GraphCompilation(mixed.length, mixed.codeStart);
    }

    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstPlan.valid) {} else {
      CoreCompilation compiledHelpers = compileTwoHelperOwners(
        firstImportedSource,
        secondImportedSource,
        rootSource,
        output
      );
      return new GraphCompilation(compiledHelpers.length, compiledHelpers.codeStart);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ 2
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);
    GraphCompilation compiled = compileGraphSource(secondLinkedSource, output);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  /// Compiles one complete validated two-module graph without topology dispatch.
  public GraphCompilation compileGraphWithConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planTwoGraph(firstImportedSource, secondImportedSource, rootSource);
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    ConstantPlanExecution execution = executeConstantPlan(
      plan,
      firstImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < execution.length) {
      return new GraphCompilation(execution.length, execution.codeStart);
    }

    region sourceTableArena = new region(
      /* bytes= */ SOURCE_TABLE_ARENA_BYTES,
      /* allocations= */ 2
    );
    bytes sourceStorage = allocateBytes(sourceTableArena, SOURCE_TABLE_BYTES);
    words sourceLengths = allocate(sourceTableArena, SOURCE_TABLE_LENGTH_WORDS);
    boolean initialized = initializePlannedSourceTable(
      plan,
      firstImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      secondImportedSource,
      sourceStorage,
      sourceLengths
    );
    assert(initialized);
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFirst = copyPlannedTableSource(
      plan,
      plannedNodeAt(plan, 0),
      sourceStorage,
      sourceLengths,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSecond = copyPlannedTableSource(
      plan,
      plannedNodeAt(plan, 1),
      sourceStorage,
      sourceLengths,
      secondArena
    );
    drop(sourceLengths);
    drop(sourceStorage);
    drop(sourceTableArena);
    GraphCompilation compiled = new GraphCompilation(0, 0);
    if (plan.edgeCount == 0) {
      assert(plan.rootCount == GRAPH_SOURCE_COUNT_TWO);
      compiled = compileTwoDirectImports(plannedFirst, plannedSecond, rootSource, output);
    } else {
      assert(plan.edgeCount == 1);
      if (plan.rootCount == 1) {
        compiled = compileConstantChain(plannedFirst, plannedSecond, rootSource, output);
      } else {
        assert(plan.rootCount == GRAPH_SOURCE_COUNT_TWO);
        RedundantTwoCompilation redundant = compileRedundantTwoGraph(
          plannedFirst,
          plannedSecond,
          rootSource,
          output
        );
        compiled = new GraphCompilation(redundant.length, redundant.codeStart);
      }
    }

    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    return compiled;
  }

  private GraphCompilation compileThreeConstantChainIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan middlePlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (middlePlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new GraphCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, middlePlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      middlePlan,
      dependentBytes
    );
    assert(dependentWritten == middlePlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new GraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

  private GraphCompilation compileConstantForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 2
    );
    if (firstLeafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstLeafPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstLeafPlan,
      firstBytes
    );
    assert(firstWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedSource,
      /* expectedImportCount= */ 2
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedSource);
      drop(firstArena);
      return new GraphCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondLeafPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedSource,
      secondLeafPlan,
      secondBytes
    );
    assert(secondWritten == secondLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(secondBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new GraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  private GraphCompilation compileMixedConstantsIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan dependentPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (dependentPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new GraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, dependentPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      dependentPlan,
      rootBytes
    );
    assert(rootWritten == dependentPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan directPlan = planConstantImport(
      directSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ 2
    );
    if (directPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new GraphCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      firstLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  private GraphCompilation compileThreeDirectImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    MixedThreeCompilation mixed = compileMixedThreeDirectGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return new GraphCompilation(mixed.length, mixed.codeStart);
    }

    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    if (firstPlan.valid) {} else {
      CoreCompilation compiledHelpers = compileThreeHelperOwners(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        rootSource,
        output
      );
      return new GraphCompilation(compiledHelpers.length, compiledHelpers.codeStart);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);
    GraphCompilation compiled = compileGraphSource(thirdLinkedSource, output);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  private GraphCompilation compilePlannedThreeGraph(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    ConstantPlanExecution execution = executeConstantPlan(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      thirdSource,
      thirdSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < execution.length) {
      return new GraphCompilation(execution.length, execution.codeStart);
    }

    region sourceTableArena = new region(
      /* bytes= */ SOURCE_TABLE_ARENA_BYTES,
      /* allocations= */ 2
    );
    bytes sourceStorage = allocateBytes(sourceTableArena, SOURCE_TABLE_BYTES);
    words sourceLengths = allocate(sourceTableArena, SOURCE_TABLE_LENGTH_WORDS);
    boolean initialized = initializePlannedSourceTable(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      thirdSource,
      thirdSource,
      thirdSource,
      thirdSource,
      sourceStorage,
      sourceLengths
    );
    assert(initialized);
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFirst = copyPlannedTableSource(
      plan,
      threeFirstSource(plan),
      sourceStorage,
      sourceLengths,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSecond = copyPlannedTableSource(
      plan,
      threeSecondSource(plan),
      sourceStorage,
      sourceLengths,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedThird = copyPlannedTableSource(
      plan,
      threeThirdSource(plan),
      sourceStorage,
      sourceLengths,
      thirdArena
    );
    drop(sourceLengths);
    drop(sourceStorage);
    drop(sourceTableArena);
    GraphCompilation compiled = new GraphCompilation(0, 0);
    if (plan.edgeCount == 0) {
      assert(plan.rootCount == GRAPH_SOURCE_COUNT_THREE);
      compiled = compileThreeDirectImports(
        plannedFirst,
        plannedSecond,
        plannedThird,
        rootSource,
        output
      );
    } else {
      if (plan.edgeCount == 1) {
        assert(plan.rootCount == GRAPH_SOURCE_COUNT_TWO);
        compiled = compileMixedConstantsIfOrdered(
          plannedFirst,
          plannedSecond,
          plannedThird,
          rootSource,
          output
        );
      } else {
        assert(plan.edgeCount == GRAPH_SOURCE_COUNT_TWO);
        if (plan.rootCount == GRAPH_SOURCE_COUNT_THREE) {
          ThreeDirectLeafCompilation shared = compileThreeDirectLeafGraph(
            plannedFirst,
            plannedSecond,
            plannedThird,
            rootSource,
            output
          );
          compiled = new GraphCompilation(shared.length, shared.codeStart);
        } else {
          assert(plan.rootCount == 1);
          if (plannedEdge(plan, threeFirstSource(plan), threeThirdSource(plan))) {
            compiled = compileConstantForkIfOrdered(
              plannedFirst,
              plannedSecond,
              plannedThird,
              rootSource,
              output
            );
          } else {
            compiled = compileThreeConstantChainIfOrdered(
              plannedFirst,
              plannedSecond,
              plannedThird,
              rootSource,
              output
            );
          }
        }
      }
    }

    drop(plannedThird);
    drop(thirdArena);
    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    assert(0 < compiled.length);
    return compiled;
  }

  /// Compiles one root with one exact three-module constant tree plan.
  public GraphCompilation compileGraphWithThreeConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planThreeGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource
    );
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    return compilePlannedThreeGraph(
      plan,
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
  }

  /// Compiles one supported six-module scalar-constant graph and its root.
  public GraphCompilation compileGraphWithSixConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixGraphCompilation compiled = compileSixConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      sixthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one supported seven-module scalar-constant graph and its root.
  public GraphCompilation compileGraphWithSevenConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 seventhImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SevenGraphCompilation compiled = compileSevenConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      sixthImportedSource,
      seventhImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one supported five-module scalar-constant graph and its root.
  public GraphCompilation compileGraphWithFiveConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphCompilation compiled = compileFiveConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with a supported four-module constant graph.
  public GraphCompilation compileGraphWithFourConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FourGraphCompilation compiled = compileFourConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }
}
