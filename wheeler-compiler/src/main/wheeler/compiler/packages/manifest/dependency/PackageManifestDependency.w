//! Composes one package-manifest dependency row verdict.

module wheeler.compiler.packages.manifest_dependency;

import wheeler.compiler.packages.manifest_dependency_name;
import wheeler.compiler.packages.manifest_dependency_prefix;
import wheeler.compiler.packages.manifest_dependency_version;

classical class PackageManifestDependency {
  /// Returns the dependency kind for one complete row, or zero when the row is malformed.
  public long manifestDependencyRowKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long kind = manifestDependencyPrefix(source, kinds, starts, lengths, count, cursor);
    if (kind < 1) {
      return 0;
    }

    boolean validName = manifestDependencyNameValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validName == false) {
      return 0;
    }

    boolean validVersion = manifestDependencyVersionValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validVersion == false) {
      return 0;
    }

    return kind;
  }
}
