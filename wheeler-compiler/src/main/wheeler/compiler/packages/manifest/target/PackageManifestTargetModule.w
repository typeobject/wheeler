//! Validates optional package-manifest target modules.

module wheeler.compiler.packages.manifest_target_module;

import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.names;

classical class PackageManifestTargetModule {
  /// Checks one quoted module-name token.
  public boolean manifestTargetModuleValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long moduleToken
  ) {
    boolean moduleQuoted = quoted(kinds, lengths, moduleToken);
    if (moduleQuoted == false) {
      return false;
    }

    long tokenStart = starts[moduleToken];
    long tokenLength = lengths[moduleToken];
    long moduleStart = tokenStart + 1;
    long moduleLength = tokenLength - 2;
    boolean moduleValid = validModuleName(source, moduleStart, moduleLength);
    return moduleValid;
  }
}
