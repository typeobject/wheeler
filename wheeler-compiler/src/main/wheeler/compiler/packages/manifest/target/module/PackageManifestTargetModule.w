//! Validates optional package-manifest target modules.

module wheeler.compiler.packages.manifest_target_module;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.names;

classical class PackageManifestTargetModule {
  /// Checks whether the optional `module` field starts at one token.
  public boolean manifestTargetModulePresent(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long keyToken
  ) {
    long keyHash = 3226183276;
    boolean present = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken,
      keyHash
    );
    return present;
  }

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
