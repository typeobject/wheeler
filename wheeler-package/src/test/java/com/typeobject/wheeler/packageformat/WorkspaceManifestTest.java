package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.WorkspaceManifest.Member;
import java.util.List;
import org.junit.jupiter.api.Test;

class WorkspaceManifestTest {
  @Test
  void parserCanonicalizesMemberOrderAndComments() {
    WorkspaceManifestParser parser = new WorkspaceManifestParser();
    WorkspaceManifest manifest = parser.parse("""
        workspace "wheeler.bootstrap" profile "bootstrap-1";
        // Source order does not establish build order.
        member "runtime" path "wheeler-runtime";
        member "examples" path "wheeler-examples";
        """);

    assertEquals(List.of("examples", "runtime"),
        manifest.members().stream().map(Member::name).toList());
    assertEquals(manifest, parser.parse(manifest.canonicalText()));
    assertEquals(64, manifest.identity().length());
  }

  @Test
  void duplicateNestedAndEscapingMembersFailClosed() {
    assertThrows(PackageFormatException.class, () -> new WorkspaceManifest(
        "root", "bootstrap-1", List.of(new Member("a", "pkg"), new Member("b", "pkg"))));
    assertThrows(PackageFormatException.class, () -> new WorkspaceManifest(
        "root", "bootstrap-1", List.of(new Member("a", "pkg"), new Member("b", "pkg/sub"))));
    assertThrows(PackageFormatException.class, () -> new Member("a", "../outside"));
  }

  @Test
  void malformedWorkspaceReportsSourceLocation() {
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> new WorkspaceManifestParser().parse("""
            workspace "root" profile "bootstrap-1";
            plugin "bad" path "pkg";
            """));
    assertTrue(failure.getMessage().contains("workspace:2:1"));
    assertThrows(
        PackageFormatException.class,
        () -> new WorkspaceManifestParser().parse(new byte[] {(byte) 0xc3}));
  }
}
