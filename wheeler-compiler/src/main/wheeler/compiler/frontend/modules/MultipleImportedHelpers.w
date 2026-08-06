//! Links bounded direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.multiple_imported_helpers;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MultipleImportedHelpers {
  private CoreCompilation compileOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan
  ) {
    HelperOwner first = importedHelperOwner(
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount
    );
    HelperOwner second = importedHelperOwner(
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount
    );
    return compileMinimalCoreWithHelperOwners(source, output, twoHelperOwners(first, second));
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
      return writeCanonicalHelperImport(firstSource, rootSource, plan, output);
    }

    if (source == 1) {
      return writeCanonicalHelperImport(secondSource, rootSource, plan, output);
    }

    return writeCanonicalHelperImport(thirdSource, rootSource, plan, output);
  }

  private CoreCompilation compileThreeOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan
  ) {
    HelperOwner first = importedHelperOwner(
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount
    );
    HelperOwner second = importedHelperOwner(
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount
    );
    HelperOwner third = importedHelperOwner(
      thirdPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerLength,
      thirdPlan.importedHelperCount
    );
    return compileMinimalCoreWithHelperOwners(
      source,
      output,
      threeHelperOwners(first, second, third)
    );
  }

  private LinkPlan fourHelperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, /* expectedImportCount= */ 4);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, /* expectedImportCount= */ 4);
    }

    if (source == 2) {
      return planResolvedHelperImport(thirdSource, rootSource, /* expectedImportCount= */ 4);
    }

    return planResolvedHelperImport(fourthSource, rootSource, /* expectedImportCount= */ 4);
  }

  private long writeFourHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    LinkPlan plan,
    borrow mut bytes output
  ) {
    if (source == 0) {
      return writeCanonicalHelperImport(firstSource, rootSource, plan, output);
    }

    if (source == 1) {
      return writeCanonicalHelperImport(secondSource, rootSource, plan, output);
    }

    if (source == 2) {
      return writeCanonicalHelperImport(thirdSource, rootSource, plan, output);
    }

    return writeCanonicalHelperImport(fourthSource, rootSource, plan, output);
  }

  private long importRank(
    long source,
    long firstStart,
    long secondStart,
    long thirdStart,
    long fourthStart
  ) {
    long selected = firstStart;
    if (source == 1) {
      selected = secondStart;
    }

    if (source == 2) {
      selected = thirdStart;
    }

    if (source == 3) {
      selected = fourthStart;
    }

    long rank = 0;
    if (firstStart < selected) {
      rank += 1;
    }

    if (secondStart < selected) {
      rank += 1;
    }

    if (thirdStart < selected) {
      rank += 1;
    }

    if (fourthStart < selected) {
      rank += 1;
    }

    return rank;
  }

  private long sourceAtRank(long rank, long firstRank, long secondRank, long thirdRank) {
    if (firstRank == rank) {
      return 0;
    }

    if (secondRank == rank) {
      return 1;
    }

    if (thirdRank == rank) {
      return 2;
    }

    return 3;
  }

  private CoreCompilation compileFourOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan,
    LinkPlan fourthPlan
  ) {
    HelperOwner first = importedHelperOwner(
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount
    );
    HelperOwner second = importedHelperOwner(
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount
    );
    HelperOwner third = importedHelperOwner(
      thirdPlan.linkedOwnerStart,
      thirdPlan.linkedOwnerLength,
      thirdPlan.importedHelperCount
    );
    HelperOwner fourth = importedHelperOwner(
      fourthPlan.linkedOwnerStart,
      fourthPlan.linkedOwnerLength,
      fourthPlan.importedHelperCount
    );
    return compileMinimalCoreWithHelperOwners(
      source,
      output,
      fourHelperOwners(first, second, third, fourth)
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
      laterWritten = writeCanonicalHelperImport(secondSource, rootSource, laterPlan, laterBytes);
    } else {
      laterWritten = writeCanonicalHelperImport(firstSource, rootSource, laterPlan, laterBytes);
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
      earlierWritten = writeCanonicalHelperImport(
        firstSource,
        laterLinkedSource,
        earlierPlan,
        earlierBytes
      );
    } else {
      earlierWritten = writeCanonicalHelperImport(
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

  /// Links four direct helper modules in root-import order, independent of frame order.
  public CoreCompilation compileFourHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstInputPlan = fourHelperPlanAt(
      0,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
    );
    LinkPlan secondInputPlan = fourHelperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
    );
    LinkPlan thirdInputPlan = fourHelperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
    );
    LinkPlan fourthInputPlan = fourHelperPlanAt(
      3,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
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

    if (fourthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    long firstRank = importRank(
      0,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart
    );
    long secondRank = importRank(
      1,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart
    );
    long thirdRank = importRank(
      2,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart
    );
    long latest = sourceAtRank(3, firstRank, secondRank, thirdRank);
    long third = sourceAtRank(2, firstRank, secondRank, thirdRank);
    long second = sourceAtRank(1, firstRank, secondRank, thirdRank);
    long earliest = sourceAtRank(0, firstRank, secondRank, thirdRank);

    LinkPlan latestPlan = fourHelperPlanAt(
      latest,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
    );
    region latestArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes latestBytes = allocateBytes(latestArena, latestPlan.linkedLength);
    long latestWritten = writeFourHelperAt(
      latest,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      latestPlan,
      latestBytes
    );
    assert(latestWritten == latestPlan.linkedLength);
    utf8 latestLinkedSource = freezeUtf8(latestBytes);

    LinkPlan thirdPlan = fourHelperPlanAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      latestLinkedSource
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeFourHelperAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      latestLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan secondPlan = fourHelperPlanAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      thirdLinkedSource
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeFourHelperAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      thirdLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan earliestPlan = fourHelperPlanAt(
      earliest,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      secondLinkedSource
    );
    if (earliestPlan.valid) {} else {
      assert(0 == 1);
    }

    region earliestArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes earliestBytes = allocateBytes(earliestArena, earliestPlan.linkedLength);
    long earliestWritten = writeFourHelperAt(
      earliest,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      secondLinkedSource,
      earliestPlan,
      earliestBytes
    );
    assert(earliestWritten == earliestPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(earliestBytes);
    CoreCompilation compiled = compileFourOwnedHelpers(
      linkedSource,
      output,
      earliestPlan,
      secondPlan,
      thirdPlan,
      latestPlan
    );
    drop(linkedSource);
    drop(earliestArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(latestLinkedSource);
    drop(latestArena);
    return compiled;
  }
}
