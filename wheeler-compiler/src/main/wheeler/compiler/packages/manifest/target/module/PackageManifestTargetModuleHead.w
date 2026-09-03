//! Composes the optional value and sources key of one modular target row.

module wheeler.compiler.packages.manifest_target_module_head;

import wheeler.compiler.packages.manifest_target_module;
import wheeler.compiler.packages.manifest_target_source;

classical class PackageManifestTargetModuleHead {
  /// Checks the optional value and required sources key after presence is known.
  public boolean manifestTargetModuleHeadValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long moduleToken,
    long sourcesKeyToken
  ) {
    boolean validModule = manifestTargetModuleValid(
      source,
      kinds,
      starts,
      lengths,
      moduleToken
    );
    if (validModule == false) {
      return false;
    }

    boolean sourcesPresent = manifestTargetSourcesPresent(
      source,
      kinds,
      starts,
      lengths,
      count,
      sourcesKeyToken
    );
    if (sourcesPresent == false) {
      return false;
    }

    return true;
  }
}
