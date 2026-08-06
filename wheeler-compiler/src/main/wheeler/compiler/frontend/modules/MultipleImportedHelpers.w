//! Links bounded direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.multiple_imported_helpers;

import wheeler.compiler.compiler_core;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MultipleImportedHelpers {
  private CoreCompilation compileOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan
  ) {
    return compileMinimalCoreWithHelperImports(
      source,
      output,
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount,
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount
    );
  }

  private LinkPlan helperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, expectedImportCount);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, expectedImportCount);
    }

    return planResolvedHelperImport(thirdSource, rootSource, expectedImportCount);
  }

  private long writeHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    LinkPlan plan,
    borrow mut bytes output
  ) {
    if (source == 0) {
      return writeConstantImport(firstSource, rootSource, plan, output);
    }

    if (source == 1) {
      return writeConstantImport(secondSource, rootSource, plan, output);
    }

    return writeConstantImport(thirdSource, rootSource, plan, output);
  }

  private CoreCompilation compileThreeOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan
  ) {
    return compileMinimalCoreWithThreeHelperImports(
      source,
      output,
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount,
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount,
      thirdPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerLength,
      thirdPlan.importedHelperCount
    );
  }

  /// Links two direct helper modules and preserves both canonical function owners.
  public CoreCompilation compileTwoHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planResolvedHelperImport(
      firstSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    LinkPlan secondPlan = planResolvedHelperImport(
      secondSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    boolean firstIsEarlier = firstPlan.linkedOwnerStart < secondPlan.linkedOwnerStart;
    LinkPlan laterPlan = firstPlan;
    if (firstIsEarlier) {
      laterPlan = secondPlan;
    }

    region laterArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes laterBytes = allocateBytes(laterArena, laterPlan.linkedLength);
    long laterWritten = 0;
    if (firstIsEarlier) {
      laterWritten = writeConstantImport(secondSource, rootSource, laterPlan, laterBytes);
    } else {
      laterWritten = writeConstantImport(firstSource, rootSource, laterPlan, laterBytes);
    }

    assert(laterWritten == laterPlan.linkedLength);
    utf8 laterLinkedSource = freezeUtf8(laterBytes);
    LinkPlan earlierPlan = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
    if (firstIsEarlier) {
      earlierPlan = planResolvedHelperImport(
        firstSource,
        laterLinkedSource,
        /* expectedImportCount= */ 2
      );
    } else {
      earlierPlan = planResolvedHelperImport(
        secondSource,
        laterLinkedSource,
        /* expectedImportCount= */ 2
      );
    }

    if (earlierPlan.valid) {} else {
      assert(0 == 1);
    }

    region earlierArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes earlierBytes = allocateBytes(earlierArena, earlierPlan.linkedLength);
    long earlierWritten = 0;
    if (firstIsEarlier) {
      earlierWritten = writeConstantImport(
        firstSource,
        laterLinkedSource,
        earlierPlan,
        earlierBytes
      );
    } else {
      earlierWritten = writeConstantImport(
        secondSource,
        laterLinkedSource,
        earlierPlan,
        earlierBytes
      );
    }

    assert(earlierWritten == earlierPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(earlierBytes);
    CoreCompilation compiled = compileOwnedHelpers(linkedSource, output, earlierPlan, laterPlan);
    drop(linkedSource);
    drop(earlierArena);
    drop(laterLinkedSource);
    drop(laterArena);
    return compiled;
  }

  /// Links three direct helper modules in root-import order, independent of frame order.
  public CoreCompilation compileThreeHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstInputPlan = helperPlanAt(
      0,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    LinkPlan secondInputPlan = helperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    LinkPlan thirdInputPlan = helperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    if (firstInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (secondInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (thirdInputPlan.valid) {} else {
      assert(0 == 1);
    }

    long earliest = 0;
    long earliestStart = firstInputPlan.linkedOwnerStart;
    if (secondInputPlan.linkedOwnerStart < earliestStart) {
      earliest = 1;
      earliestStart = secondInputPlan.linkedOwnerStart;
    }

    if (thirdInputPlan.linkedOwnerStart < earliestStart) {
      earliest = 2;
    }

    long latest = 0;
    long latestStart = firstInputPlan.linkedOwnerStart;
    if (latestStart < secondInputPlan.linkedOwnerStart) {
      latest = 1;
      latestStart = secondInputPlan.linkedOwnerStart;
    }

    if (latestStart < thirdInputPlan.linkedOwnerStart) {
      latest = 2;
    }

    long middle = 3 - earliest - latest;
    LinkPlan latestPlan = helperPlanAt(
      latest,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    region latestArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes latestBytes = allocateBytes(latestArena, latestPlan.linkedLength);
    long latestWritten = writeHelperAt(
      latest,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      latestPlan,
      latestBytes
    );
    assert(latestWritten == latestPlan.linkedLength);
    utf8 latestLinkedSource = freezeUtf8(latestBytes);

    LinkPlan middlePlan = helperPlanAt(
      middle,
      firstSource,
      secondSource,
      thirdSource,
      latestLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (middlePlan.valid) {} else {
      assert(0 == 1);
    }

    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, middlePlan.linkedLength);
    long middleWritten = writeHelperAt(
      middle,
      firstSource,
      secondSource,
      thirdSource,
      latestLinkedSource,
      middlePlan,
      middleBytes
    );
    assert(middleWritten == middlePlan.linkedLength);
    utf8 middleLinkedSource = freezeUtf8(middleBytes);

    LinkPlan earliestPlan = helperPlanAt(
      earliest,
      firstSource,
      secondSource,
      thirdSource,
      middleLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (earliestPlan.valid) {} else {
      assert(0 == 1);
    }

    region earliestArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes earliestBytes = allocateBytes(earliestArena, earliestPlan.linkedLength);
    long earliestWritten = writeHelperAt(
      earliest,
      firstSource,
      secondSource,
      thirdSource,
      middleLinkedSource,
      earliestPlan,
      earliestBytes
    );
    assert(earliestWritten == earliestPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(earliestBytes);
    CoreCompilation compiled = compileThreeOwnedHelpers(
      linkedSource,
      output,
      earliestPlan,
      middlePlan,
      latestPlan
    );
    drop(linkedSource);
    drop(earliestArena);
    drop(middleLinkedSource);
    drop(middleArena);
    drop(latestLinkedSource);
    drop(latestArena);
    return compiled;
  }
}
