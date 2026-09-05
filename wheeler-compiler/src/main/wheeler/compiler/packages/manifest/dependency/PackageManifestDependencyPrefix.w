//! Validates the prefix of one package-manifest dependency row.

module wheeler.compiler.packages.manifest_dependency_prefix;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;

classical class PackageManifestDependencyPrefix {
  /// Returns the dependency kind, or zero for an invalid row prefix.
  public long manifestDependencyPrefix(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long finalToken = cursor + 9;
    boolean bounded = finalToken < count;
    if (bounded == false) {
      return 0;
    }

    boolean sequenceRow = dashAt(source, kinds, starts, cursor);
    if (sequenceRow == false) {
      return 0;
    }

    long typeKeyToken = cursor + 1;
    long kindWord = WORD_KIND;
    boolean typeKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      typeKeyToken,
      kindWord
    );
    if (typeKey == false) {
      return 0;
    }

    long kindToken = cursor + 3;
    long kind = manifestDependencyKind(source, kinds, starts, lengths, kindToken);
    return kind;
  }
}
