//! Links one direct helper owner beside one direct constant owner.

module wheeler.compiler.graphs.direct.mixed_two;

import wheeler.compiler.compiler_core;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MixedTwoDirectGraph {
  private const long DIRECT_IMPORT_COUNT = 2;

  /// Carries compilation bounds for one admitted mixed direct graph.
  public record MixedTwoCompilation(long length, long codeStart) {}

  private MixedTwoCompilation invalidCompilation() {
    return new MixedTwoCompilation(0, 0);
  }

  private MixedTwoCompilation compileOrderedMixedTwo(
    borrow utf8 helperSource,
    borrow utf8 constantSource,
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

    LinkPlan constantPlan = planConstantImport(
      constantSource,
      helperLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (constantPlan.valid) {} else {
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region constantArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes constantBytes = allocateBytes(constantArena, constantPlan.linkedLength);
    long constantWritten = writeConstantImport(
      constantSource,
      helperLinkedRoot,
      constantPlan,
      constantBytes
    );
    assert(constantWritten == constantPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(constantBytes);
    CoreCompilation compiled = compileMinimalCoreWithHelperOwner(
      linkedRoot,
      output,
      helperPlan.linkedOwnerStart,
      helperPlan.linkedOwnerLength,
      helperPlan.importedHelperCount
    );

    drop(linkedRoot);
    drop(constantArena);
    drop(helperLinkedRoot);
    drop(helperArena);
    return new MixedTwoCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles exactly one helper owner and one constant owner in either frame order.
  public MixedTwoCompilation compileMixedTwoDirectGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstHelper = planResolvedHelperImport(
      firstSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstHelper.valid) {
      return compileOrderedMixedTwo(firstSource, secondSource, rootSource, output);
    }

    LinkPlan secondHelper = planResolvedHelperImport(
      secondSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (secondHelper.valid) {
      return compileOrderedMixedTwo(secondSource, firstSource, rootSource, output);
    }

    return invalidCompilation();
  }
}
