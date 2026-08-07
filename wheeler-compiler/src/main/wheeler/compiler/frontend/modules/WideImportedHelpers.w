//! Links five direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.wide_imported_helpers;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.helper_source_network;
import wheeler.compiler.helper_source_order;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class WideImportedHelpers {
  private LinkPlan helperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 2) {
      return planResolvedHelperImport(thirdSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 3) {
      return planResolvedHelperImport(fourthSource, rootSource, /* expectedImportCount= */ 5);
    }

    return planResolvedHelperImport(fifthSource, rootSource, /* expectedImportCount= */ 5);
  }

  private long writeHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
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

    return writeCanonicalHelperImport(fifthSource, rootSource, plan, output);
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
    LinkPlan fifthPlan
  ) {
    HelperOwners owners = fiveHelperOwners(
      owner(firstPlan),
      owner(secondPlan),
      owner(thirdPlan),
      owner(fourthPlan),
      owner(fifthPlan)
    );
    return compileMinimalCoreWithHelperOwners(source, output, owners);
  }

  /// Links five direct helper modules independent of source-frame order.
  public CoreCompilation compileFiveHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
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
      rootSource
    );
    LinkPlan secondInputPlan = helperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan thirdInputPlan = helperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan fourthInputPlan = helperPlanAt(
      3,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan fifthInputPlan = helperPlanAt(
      4,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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

    long[7] ownerKeys = new long[7](
      firstInputPlan.linkedOwnerStart * SOURCE_PACK_SCALE,
      secondInputPlan.linkedOwnerStart * SOURCE_PACK_SCALE + 1,
      thirdInputPlan.linkedOwnerStart * SOURCE_PACK_SCALE + 2,
      fourthInputPlan.linkedOwnerStart * SOURCE_PACK_SCALE + 3,
      fifthInputPlan.linkedOwnerStart * SOURCE_PACK_SCALE + 4,
      MAX_LINKED_SOURCE_BYTES * SOURCE_PACK_SCALE + 5,
      MAX_LINKED_SOURCE_BYTES * SOURCE_PACK_SCALE + 6
    );
    long fifthKey = helperSourceKeyAtRank(
      4,
      ownerKeys[0],
      ownerKeys[1],
      ownerKeys[2],
      ownerKeys[3],
      ownerKeys[4],
      ownerKeys[5],
      ownerKeys[6]
    );
    long fifth = fifthKey % SOURCE_PACK_SCALE;
    long fourthKey = helperSourceKeyAtRank(
      3,
      ownerKeys[0],
      ownerKeys[1],
      ownerKeys[2],
      ownerKeys[3],
      ownerKeys[4],
      ownerKeys[5],
      ownerKeys[6]
    );
    long fourth = fourthKey % SOURCE_PACK_SCALE;
    long thirdKey = helperSourceKeyAtRank(
      2,
      ownerKeys[0],
      ownerKeys[1],
      ownerKeys[2],
      ownerKeys[3],
      ownerKeys[4],
      ownerKeys[5],
      ownerKeys[6]
    );
    long third = thirdKey % SOURCE_PACK_SCALE;
    long secondKey = helperSourceKeyAtRank(
      1,
      ownerKeys[0],
      ownerKeys[1],
      ownerKeys[2],
      ownerKeys[3],
      ownerKeys[4],
      ownerKeys[5],
      ownerKeys[6]
    );
    long second = secondKey % SOURCE_PACK_SCALE;
    long firstKey = helperSourceKeyAtRank(
      0,
      ownerKeys[0],
      ownerKeys[1],
      ownerKeys[2],
      ownerKeys[3],
      ownerKeys[4],
      ownerKeys[5],
      ownerKeys[6]
    );
    long first = firstKey % SOURCE_PACK_SCALE;

    LinkPlan fifthPlan = helperPlanAt(
      fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeHelperAt(
      fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);

    LinkPlan fourthPlan = helperPlanAt(
      fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthLinkedSource
    );
    if (fourthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeHelperAt(
      fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan thirdPlan = helperPlanAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fourthLinkedSource
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeHelperAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fourthLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan secondPlan = helperPlanAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      thirdLinkedSource
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeHelperAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      thirdLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan firstPlan = helperPlanAt(
      first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      secondLinkedSource
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeHelperAt(
      first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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
      fifthPlan
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
    return compiled;
  }
}
