//! Links one direct helper owner beside two direct constant owners.

module wheeler.compiler.graphs.direct.mixed_three;

import wheeler.compiler.compiler_core;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MixedThreeDirectGraph {
  private const long DIRECT_IMPORT_COUNT = 3;

  /// Carries compilation bounds for one admitted mixed direct graph.
  public record MixedThreeCompilation(long length, long codeStart) {}

  private MixedThreeCompilation invalidCompilation() {
    return new MixedThreeCompilation(0, 0);
  }

  private MixedThreeCompilation compileOrderedMixedThree(
    borrow utf8 helperSource,
    borrow utf8 firstConstantSource,
    borrow utf8 secondConstantSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan helperPlan = planResolvedHelperImport(
      helperSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (helperPlan.valid) {} else {
      return invalidCompilation();
    }

    region helperArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes helperBytes = allocateBytes(helperArena, helperPlan.linkedLength);
    long helperWritten = writeConstantImport(helperSource, rootSource, helperPlan, helperBytes);
    assert(helperWritten == helperPlan.linkedLength);
    utf8 helperLinkedRoot = freezeUtf8(helperBytes);

    LinkPlan firstPlan = planConstantImport(
      firstConstantSource,
      helperLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstPlan.valid) {} else {
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstConstantSource,
      helperLinkedRoot,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedRoot = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondConstantSource,
      firstLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedRoot);
      drop(firstArena);
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondConstantSource,
      firstLinkedRoot,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(secondBytes);
    CoreCompilation compiled = compileMinimalCoreWithHelperOwner(
      linkedRoot,
      output,
      helperPlan.linkedOwnerStart,
      helperPlan.linkedOwnerLength,
      helperPlan.importedHelperCount
    );

    drop(linkedRoot);
    drop(secondArena);
    drop(firstLinkedRoot);
    drop(firstArena);
    drop(helperLinkedRoot);
    drop(helperArena);
    return new MixedThreeCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles exactly one helper owner and two constant owners in any frame order.
  public MixedThreeCompilation compileMixedThreeDirectGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstHelper = planResolvedHelperImport(
      firstSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstHelper.valid) {
      return compileOrderedMixedThree(
        firstSource,
        secondSource,
        thirdSource,
        rootSource,
        output
      );
    }

    LinkPlan secondHelper = planResolvedHelperImport(
      secondSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (secondHelper.valid) {
      return compileOrderedMixedThree(
        secondSource,
        firstSource,
        thirdSource,
        rootSource,
        output
      );
    }

    LinkPlan thirdHelper = planResolvedHelperImport(
      thirdSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (thirdHelper.valid) {
      return compileOrderedMixedThree(
        thirdSource,
        firstSource,
        secondSource,
        rootSource,
        output
      );
    }

    return invalidCompilation();
  }
}
