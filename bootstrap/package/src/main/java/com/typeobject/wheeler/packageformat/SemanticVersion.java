package com.typeobject.wheeler.packageformat;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/** Strict comparable three-part semantic version with optional prerelease. */
public record SemanticVersion(long major, long minor, long patch, List<String> prerelease)
    implements Comparable<SemanticVersion> {
  public SemanticVersion {
    if (major < 0 || minor < 0 || patch < 0) {
      throw new PackageFormatException("Negative semantic version component");
    }
    prerelease = List.copyOf(prerelease);
  }

  public static SemanticVersion parse(String text) {
    Objects.requireNonNull(text, "text");
    String[] releaseAndPre = text.split("-", 2);
    String[] numbers = releaseAndPre[0].split("\\.", -1);
    if (numbers.length != 3) {
      throw new PackageFormatException("Invalid semantic version " + text);
    }
    List<String> pre = new ArrayList<>();
    if (releaseAndPre.length == 2) {
      if (releaseAndPre[1].isEmpty()) {
        throw new PackageFormatException("Invalid semantic prerelease " + text);
      }
      for (String identifier : releaseAndPre[1].split("\\.", -1)) {
        if (identifier.isEmpty() || !identifier.matches("[0-9A-Za-z-]+")
            || (identifier.chars().allMatch(Character::isDigit)
                && !identifier.matches("0|[1-9][0-9]*"))) {
          throw new PackageFormatException("Invalid semantic prerelease " + text);
        }
        pre.add(identifier);
      }
    }
    return new SemanticVersion(
        component(numbers[0], text),
        component(numbers[1], text),
        component(numbers[2], text),
        pre);
  }

  @Override
  public int compareTo(SemanticVersion other) {
    int release = compareRelease(other);
    if (release != 0) {
      return release;
    }
    if (prerelease.isEmpty() || other.prerelease.isEmpty()) {
      return prerelease.isEmpty() ? (other.prerelease.isEmpty() ? 0 : 1) : -1;
    }
    int common = Math.min(prerelease.size(), other.prerelease.size());
    for (int index = 0; index < common; index++) {
      int comparison = compareIdentifier(prerelease.get(index), other.prerelease.get(index));
      if (comparison != 0) {
        return comparison;
      }
    }
    return Integer.compare(prerelease.size(), other.prerelease.size());
  }

  @Override
  public String toString() {
    String release = major + "." + minor + "." + patch;
    return prerelease.isEmpty() ? release : release + "-" + String.join(".", prerelease);
  }

  private int compareRelease(SemanticVersion other) {
    int result = Long.compare(major, other.major);
    if (result == 0) {
      result = Long.compare(minor, other.minor);
    }
    return result == 0 ? Long.compare(patch, other.patch) : result;
  }

  private static int compareIdentifier(String left, String right) {
    boolean leftNumeric = left.chars().allMatch(Character::isDigit);
    boolean rightNumeric = right.chars().allMatch(Character::isDigit);
    if (leftNumeric && rightNumeric) {
      int length = Integer.compare(left.length(), right.length());
      return length == 0 ? left.compareTo(right) : length;
    }
    if (leftNumeric != rightNumeric) {
      return leftNumeric ? -1 : 1;
    }
    return left.compareTo(right);
  }

  private static long component(String value, String source) {
    if (!value.matches("0|[1-9][0-9]*")) {
      throw new PackageFormatException("Invalid semantic version " + source);
    }
    try {
      return Long.parseLong(value);
    } catch (NumberFormatException exception) {
      throw new PackageFormatException("Semantic version component is too large", exception);
    }
  }
}
