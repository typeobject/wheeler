//! Links six direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.six_imported_helpers;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.helper_source_order;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class SixImportedHelpers {
  private LinkPlan helperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, /* expectedImportCount= */ 6);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, /* expectedImportCount= */ 6);
    }

    if (source == 2) {
      return planResolvedHelperImport(thirdSource, rootSource, /* expectedImportCount= */ 6);
    }

    if (source == 3) {
      return planResolvedHelperImport(fourthSource, rootSource, /* expectedImportCount= */ 6);
    }

    if (source == 4) {
      return planResolvedHelperImport(fifthSource, rootSource, /* expectedImportCount= */ 6);
    }

    return planResolvedHelperImport(sixthSource, rootSource, /* expectedImportCount= */ 6);
  }

  private long writeHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
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

    if (source == 3) {
      return writeCanonicalHelperImport(fourthSource, rootSource, plan, output);
    }

    if (source == 4) {
      return writeCanonicalHelperImport(fifthSource, rootSource, plan, output);
    }

    return writeCanonicalHelperImport(sixthSource, rootSource, plan, output);
  }

  private HelperOwner owner(LinkPlan plan) {
    return importedHelperOwner(
      plan.linkedOwnerStart,
      plan.linkedOwnerLength,
      plan.importedHelperCount
    );
  }

  private CoreCompilation compileOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan,
    LinkPlan fourthPlan,
    LinkPlan fifthPlan,
    LinkPlan sixthPlan
  ) {
    HelperOwners owners = sixHelperOwners(
      owner(firstPlan),
      owner(secondPlan),
      owner(thirdPlan),
      owner(fourthPlan),
      owner(fifthPlan),
      owner(sixthPlan)
    );
    return compileMinimalCoreWithHelperOwners(source, output, owners);
  }

  /// Links six direct helper modules independent of source-frame order.
  public CoreCompilation compileSixHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstInputPlan = helperPlanAt(
      0,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    LinkPlan secondInputPlan = helperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    LinkPlan thirdInputPlan = helperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    LinkPlan fourthInputPlan = helperPlanAt(
      3,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    LinkPlan fifthInputPlan = helperPlanAt(
      4,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    LinkPlan sixthInputPlan = helperPlanAt(
      5,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
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

    if (fifthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (sixthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    long[7] ownerStarts = new long[7](
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart,
      sixthInputPlan.linkedOwnerStart,
      0
    );
    long firstOwner = helperSourceAtRank(0, ownerStarts, 6);
    long secondOwner = helperSourceAtRank(1, ownerStarts, 6);
    long thirdOwner = helperSourceAtRank(2, ownerStarts, 6);
    long fourthOwner = helperSourceAtRank(3, ownerStarts, 6);
    long fifthOwner = helperSourceAtRank(4, ownerStarts, 6);
    long sixthOwner = helperSourceAtRank(5, ownerStarts, 6);
    LinkPlan sixthPlan = helperPlanAt(
      sixthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes sixthBytes = allocateBytes(sixthArena, sixthPlan.linkedLength);
    long sixthWritten = writeHelperAt(
      sixthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      sixthPlan,
      sixthBytes
    );
    assert(sixthWritten == sixthPlan.linkedLength);
    utf8 sixthLinkedSource = freezeUtf8(sixthBytes);

    LinkPlan fifthPlan = helperPlanAt(
      fifthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthLinkedSource
    );
    if (fifthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeHelperAt(
      fifthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthLinkedSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);

    LinkPlan fourthPlan = helperPlanAt(
      fourthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fifthLinkedSource
    );
    if (fourthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeHelperAt(
      fourthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fifthLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan thirdPlan = helperPlanAt(
      thirdOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fourthLinkedSource
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeHelperAt(
      thirdOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fourthLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan secondPlan = helperPlanAt(
      secondOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      thirdLinkedSource
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeHelperAt(
      secondOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      thirdLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan firstPlan = helperPlanAt(
      firstOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      secondLinkedSource
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeHelperAt(
      firstOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      secondLinkedSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(firstBytes);
    CoreCompilation compiled = compileOwnedHelpers(
      linkedSource,
      output,
      firstPlan,
      secondPlan,
      thirdPlan,
      fourthPlan,
      fifthPlan,
      sixthPlan
    );
    drop(linkedSource);
    drop(firstArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(fourthLinkedSource);
    drop(fourthArena);
    drop(fifthLinkedSource);
    drop(fifthArena);
    drop(sixthLinkedSource);
    drop(sixthArena);
    return compiled;
  }
}
