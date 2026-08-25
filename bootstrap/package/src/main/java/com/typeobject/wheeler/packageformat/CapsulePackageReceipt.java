package com.typeobject.wheeler.packageformat;

/** Resolution and build evidence for one package instance in an application capsule. */
public record CapsulePackageReceipt(
    String repositorySnapshot,
    String coordinate,
    String rrev,
    String variant,
    String buildInput,
    String prev,
    String selectedExport,
    String instance) {
  public CapsulePackageReceipt {
    CapsuleRoot.requireHash(repositorySnapshot, "repository snapshot");
    coordinate = requireCoordinate(coordinate);
    CapsuleRoot.requireHash(rrev, "RREV");
    variant = CapsuleRoot.requireToken(variant, "receipt variant");
    CapsuleRoot.requireHash(buildInput, "build input");
    CapsuleRoot.requireHash(prev, "PREV");
    selectedExport = CapsuleRoot.requireToken(selectedExport, "selected export");
    CapsuleRoot.requireHash(instance, "package instance");
  }

  private static String requireCoordinate(String value) {
    if (value == null
        || !value.matches("[a-z][a-z0-9_.-]{0,127}@[0-9A-Za-z][0-9A-Za-z.+-]{0,63}")) {
      throw new PackageFormatException("Invalid capsule package coordinate");
    }
    return value;
  }
}
