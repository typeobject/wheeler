package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for ordered repository policy and its closed YAML schema. */
class RepositoryPolicyTest {
  @Test
  void policyPreservesTrustOrderWhileCanonicalizingNamespaceSets() {
    RepositoryPolicy policy = new RepositoryPolicy(
        1,
        List.of(
            repository("private", "1", "/srv/private", true, "zeta", "acme"),
            repository("local", "2", "/srv/local", false, "*")));
    RepositoryPolicy parsed = new RepositoryPolicyParser().parse(policy.canonicalText());

    assertEquals(policy, parsed);
    assertEquals(List.of("private", "local"),
        parsed.repositories().stream().map(Repository::alias).toList());
    assertEquals(List.of("acme", "zeta"), parsed.repositories().getFirst().namespaces());
    assertTrue(parsed.repositories().getFirst().authoritativeFor("acme.compiler"));
    assertFalse(parsed.repositories().getFirst().authoritativeFor("other.compiler"));
    assertEquals(List.of("local", "private"), parsed.moveBefore("local", "private")
        .repositories().stream().map(Repository::alias).toList());
    assertFalse(parsed.enabled("private", false).repositories().getFirst().enabled());
  }

  @Test
  void defaultLocalIdentityDoesNotDependOnItsPhysicalLocation() {
    RepositoryPolicy first = RepositoryPolicy.defaultLocal(Path.of("/home/a/data/repository"));
    RepositoryPolicy second = RepositoryPolicy.defaultLocal(Path.of("/mnt/b/repository"));

    assertEquals(first.repositories().getFirst().identity(),
        second.repositories().getFirst().identity());
    assertEquals(64, RepositoryPolicy.localIdentity().length());
  }

  @Test
  void malformedAndAmbiguousPoliciesFailClosed() {
    RepositoryPolicy policy = new RepositoryPolicy(
        1, List.of(repository("local", "a", "/srv/local", true, "*")));
    String canonical = policy.canonicalText();

    assertThrows(PackageFormatException.class,
        () -> new RepositoryPolicyParser().parse(canonical.replace(
            "alias: \"local\"", "alias: \"local\"\n    alias: \"again\"")));
    assertThrows(PackageFormatException.class,
        () -> new RepositoryPolicyParser().parse(canonical.replace(
            "transport: \"file\"", "transport: \"https\"")));
    assertThrows(PackageFormatException.class,
        () -> new RepositoryPolicyParser().parse(canonical.replace(
            "enabled: true", "enabled: yes")));
    assertThrows(PackageFormatException.class,
        () -> new RepositoryPolicy(1, List.of(
            repository("same", "a", "/srv/a", true, "*"),
            repository("same", "b", "/srv/b", true, "*"))));
    assertThrows(PackageFormatException.class,
        () -> repository("bad", "c", "relative/repository", true, "*"));
  }

  private static Repository repository(
      String alias, String identityDigit, String path, boolean enabled, String... namespaces) {
    return new Repository(
        alias, identityDigit.repeat(64), Transport.FILE, path, enabled, List.of(namespaces));
  }
}
