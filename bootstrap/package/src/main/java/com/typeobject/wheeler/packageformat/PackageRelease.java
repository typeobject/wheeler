package com.typeobject.wheeler.packageformat;

import java.util.Objects;

/** One immutable package version available to deterministic resolution. */
public record PackageRelease(PackageManifest manifest, String archiveIdentity) {
  public PackageRelease {
    Objects.requireNonNull(manifest, "manifest");
    Objects.requireNonNull(archiveIdentity, "archiveIdentity");
    if (!archiveIdentity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid package archive identity");
    }
  }

  public SemanticVersion semanticVersion() {
    return SemanticVersion.parse(manifest.version());
  }
}
