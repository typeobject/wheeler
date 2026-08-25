//! Verifies and identifies a bounded canonical bootstrap module closure.

module wheeler.conformance.bootstrap.modules_identity;

import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.module_manifest;
import wheeler.crypto.content_identity;

classical class NativeBootstrapModulesIdentity {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_EXTERNAL_MODULES = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_MANIFEST_BYTES = 262144;
  private const long MODULE_COLUMN_ARENA_BYTES = 135000;

  state long moduleCount = 0;
  state long externalCount = 0;
  state long importCount = 0;
  state long published = 0;

  /// Publishes SHA-256 for up to 512 rooted modules and sixty-four externals.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < MAX_MANIFEST_BYTES + 1, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(/* bytes= */ MODULE_COLUMN_ARENA_BYTES, /* allocations= */ 16);
    bytes expected = allocateBytes(arena, /* length= */ 256);
    words externalStarts = allocate(arena, MAX_EXTERNAL_MODULES);
    words externalLengths = allocate(arena, MAX_EXTERNAL_MODULES);
    words moduleStarts = allocate(arena, MAX_LOCAL_MODULES);
    words moduleLengths = allocate(arena, MAX_LOCAL_MODULES);
    words sourceStarts = allocate(arena, MAX_LOCAL_MODULES);
    words sourceLengths = allocate(arena, MAX_LOCAL_MODULES);
    words identityStarts = allocate(arena, MAX_LOCAL_MODULES);
    words edgeOwners = allocate(arena, MAX_IMPORTS);
    words edgeStarts = allocate(arena, MAX_IMPORTS);
    words edgeLengths = allocate(arena, MAX_IMPORTS);
    words edgeTargets = allocate(arena, MAX_IMPORTS);
    BootstrapModuleManifestPlan plan = parseBootstrapModuleManifest(
      source,
      expected,
      externalStarts,
      externalLengths,
      moduleStarts,
      moduleLengths,
      sourceStarts,
      sourceLengths,
      identityStarts,
      edgeOwners,
      edgeStarts,
      edgeLengths,
      edgeTargets
    );

    publishSha256(source, identity, arena);
    moduleCount = plan.moduleCount;
    externalCount = plan.externalCount;
    importCount = plan.importCount;
    published = 1;
    setOutputLength(identity, 32);
    drop(edgeTargets);
    drop(edgeLengths);
    drop(edgeStarts);
    drop(edgeOwners);
    drop(identityStarts);
    drop(sourceLengths);
    drop(sourceStarts);
    drop(moduleLengths);
    drop(moduleStarts);
    drop(externalLengths);
    drop(externalStarts);
    drop(expected);
    drop(arena);
  }
}
