package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Validates one closed bootstrap-seed ancestry and its independent attestations. */
public final class BootstrapSeedChain {
  private static final int MAX_DEPTH = 1_024;
  private final Map<String, BootstrapSeedRecord> records;

  public BootstrapSeedChain(List<BootstrapSeedRecord> records) {
    if (records == null || records.isEmpty()) {
      throw new PackageFormatException("Bootstrap seed chain is empty");
    }
    if (records.size() > MAX_DEPTH) {
      throw new PackageFormatException("Bootstrap seed chain exceeds the record limit");
    }
    Map<String, BootstrapSeedRecord> indexed = new HashMap<>();
    for (BootstrapSeedRecord record : records) {
      if (record == null || indexed.put(record.identity(), record) != null) {
        throw new PackageFormatException("Duplicate bootstrap seed record");
      }
    }
    this.records = Map.copyOf(indexed);
    validateReferences();
    validateAcyclic();
  }

  public List<BootstrapSeedRecord> records() {
    return records.entrySet().stream()
        .sorted(Map.Entry.comparingByKey())
        .map(Map.Entry::getValue)
        .toList();
  }

  public List<BootstrapSeedRecord> ancestry(String leafIdentity) {
    BootstrapSeedRecord current = required(leafIdentity, "leaf seed");
    List<BootstrapSeedRecord> ancestry = new ArrayList<>();
    Set<String> seen = new HashSet<>();
    while (true) {
      if (!seen.add(current.identity())) {
        throw new PackageFormatException("Cyclic bootstrap seed ancestry");
      }
      ancestry.add(current);
      if (current.parent().isEmpty()) {
        return List.copyOf(ancestry);
      }
      if (ancestry.size() == MAX_DEPTH) {
        throw new PackageFormatException("Bootstrap seed ancestry exceeds the depth limit");
      }
      current = required(current.parent(), "parent seed");
    }
  }

  public String identity() {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      for (Map.Entry<String, BootstrapSeedRecord> entry : records.entrySet().stream()
          .sorted(Comparator.comparing(Map.Entry::getKey)).toList()) {
        digest.update(entry.getKey().getBytes(StandardCharsets.US_ASCII));
      }
      return HexFormat.of().formatHex(digest.digest());
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private void validateReferences() {
    for (BootstrapSeedRecord record : records.values()) {
      if (!record.parent().isEmpty()) {
        required(record.parent(), "parent seed");
      }
      if (record.kind() == BootstrapSeedRecord.Kind.RECOVERY_RELEASE
          && record.attestations().size() == 1) {
        throw new PackageFormatException(
            "Promoted recovery releases require zero or at least two independent attestations");
      }
      Set<String> independentBuilders = new HashSet<>();
      independentBuilders.add(record.builder());
      for (String attestation : record.attestations()) {
        BootstrapSeedRecord witness = required(attestation, "seed attestation");
        if (!witness.output().equals(record.output())) {
          throw new PackageFormatException(
              "Bootstrap seed attestation does not reproduce the recorded output");
        }
        if (!witness.source().equals(record.source())
            || !witness.sourceRevision().equals(record.sourceRevision())) {
          throw new PackageFormatException(
              "Bootstrap seed attestation does not reproduce the recorded source");
        }
        if (!independentBuilders.add(witness.builder())) {
          throw new PackageFormatException(
              "Bootstrap seed attestations must use independent builders");
        }
      }
    }
  }

  private void validateAcyclic() {
    for (String identity : records.keySet()) {
      ancestry(identity);
    }
  }

  private BootstrapSeedRecord required(String identity, String description) {
    BootstrapSeedRecord record = records.get(identity);
    if (record == null) {
      throw new PackageFormatException("Missing " + description + " " + identity);
    }
    return record;
  }
}
