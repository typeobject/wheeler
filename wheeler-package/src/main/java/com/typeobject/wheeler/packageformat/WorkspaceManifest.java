package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Immutable canonical model of one {@code wheeler.workspace} manifest. */
public record WorkspaceManifest(String name, String profile, List<Member> members) {
  private static final int MAX_MEMBERS = 10_000;

  public WorkspaceManifest {
    requireName(name, "workspace");
    requireName(profile, "profile");
    if (members.isEmpty() || members.size() > MAX_MEMBERS) {
      throw new PackageFormatException("Workspace must declare 1.." + MAX_MEMBERS + " members");
    }
    List<Member> ordered = new ArrayList<>(List.copyOf(members));
    ordered.sort(Comparator.comparing(Member::name));
    Set<String> names = new HashSet<>();
    Set<String> paths = new HashSet<>();
    for (Member member : ordered) {
      if (!names.add(member.name())) {
        throw new PackageFormatException("Duplicate workspace member " + member.name());
      }
      if (!paths.add(member.path())) {
        throw new PackageFormatException("Duplicate workspace path " + member.path());
      }
    }
    for (String left : paths) {
      for (String right : paths) {
        if (!left.equals(right) && right.startsWith(left + "/")) {
          throw new PackageFormatException(
              "Nested workspace member paths " + left + " and " + right);
        }
      }
    }
    members = List.copyOf(ordered);
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder();
    text.append("workspace \"").append(name).append("\" profile \"")
        .append(profile).append("\";\n");
    for (Member member : members) {
      text.append("member \"").append(member.name()).append("\" path \"")
          .append(member.path()).append("\";\n");
    }
    return text.toString();
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
          .digest(canonicalText().getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  public record Member(String name, String path) {
    public Member {
      requireName(name, "member");
      Objects.requireNonNull(path, "path");
      if (path.isEmpty() || path.length() > 4096 || path.startsWith("/")
          || path.endsWith("/") || path.indexOf('\\') >= 0 || path.indexOf('\0') >= 0) {
        throw new PackageFormatException("Invalid workspace member path " + path);
      }
      for (String component : path.split("/", -1)) {
        if (component.isEmpty() || component.equals(".") || component.equals("..")
            || !component.matches("[A-Za-z0-9_-]+(?:\\.[A-Za-z0-9_-]+)*")) {
          throw new PackageFormatException("Invalid workspace member path " + path);
        }
      }
    }
  }

  private static void requireName(String value, String description) {
    Objects.requireNonNull(value, description);
    if (!value.matches("[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*")) {
      throw new PackageFormatException("Invalid " + description + " name " + value);
    }
  }
}
