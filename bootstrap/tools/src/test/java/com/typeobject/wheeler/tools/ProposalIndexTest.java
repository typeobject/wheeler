package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Keeps the proposal index complete and the declared WIP dependency graph acyclic. */
final class ProposalIndexTest {
  private static final Path ROOT = Path.of("docs/docs/proposals");
  private static final Pattern FILE = Pattern.compile("WIP-(\\d{4})-[a-z0-9-]+\\.md");
  private static final Pattern HEADING = Pattern.compile("# WIP-(\\d{4}): .+");
  private static final Pattern STATUS = Pattern.compile(
      "(?m)^\\| Status \\| ([A-Za-z]+) \\|$");
  private static final Pattern DEPENDENCY = Pattern.compile("WIP-(\\d{4})");
  private static final Pattern INDEX_ROW = Pattern.compile(
      "(?m)^\\| \\[WIP-(\\d{4})]\\((WIP-[^)]+\\.md)\\) \\| ([A-Za-z]+) \\|.*$");
  private static final Set<String> STATUSES = Set.of(
      "Draft", "Review", "Accepted", "Implementing", "Implemented", "Superseded", "Withdrawn");

  private record Proposal(
      String id, String filename, String status, List<String> dependencies) {}

  private record IndexEntry(String filename, String status) {}

  @Test
  void indexNamesEveryProposalAndDependenciesRemainClosedAndAcyclic() throws Exception {
    Map<String, Proposal> proposals = loadProposals();
    Map<String, IndexEntry> indexed = loadIndex();

    assertEquals(proposals.keySet(), indexed.keySet(), "proposal index IDs");
    for (Proposal proposal : proposals.values()) {
      IndexEntry entry = indexed.get(proposal.id());
      assertEquals(proposal.filename(), entry.filename(), proposal.id());
      assertEquals(proposal.status(), entry.status(), proposal.id());
      for (String dependency : proposal.dependencies()) {
        assertTrue(proposals.containsKey(dependency),
            proposal.id() + " has missing dependency WIP-" + dependency);
      }
    }

    Set<String> complete = new HashSet<>();
    Set<String> active = new HashSet<>();
    for (String id : proposals.keySet()) {
      visit(id, proposals, active, complete);
    }
  }

  private static Map<String, Proposal> loadProposals() throws IOException {
    List<Path> files;
    try (var paths = Files.list(ROOT)) {
      files = paths
          .filter(Files::isRegularFile)
          .filter(path -> FILE.matcher(path.getFileName().toString()).matches())
          .sorted()
          .toList();
    }
    Map<String, Proposal> proposals = new LinkedHashMap<>();
    for (Path path : files) {
      String filename = path.getFileName().toString();
      Matcher file = FILE.matcher(filename);
      assertTrue(file.matches(), filename);
      String id = file.group(1);
      String source = Files.readString(path);
      String firstLine = source.lines().findFirst().orElseThrow();
      Matcher heading = HEADING.matcher(firstLine);
      assertTrue(heading.matches(), filename + " heading");
      assertEquals(id, heading.group(1), filename + " heading ID");
      Matcher status = STATUS.matcher(source);
      assertTrue(status.find(), filename + " status");
      assertTrue(STATUSES.contains(status.group(1)), filename + " status vocabulary");

      String dependencyField = metadataValue(source, "Depends on");
      List<String> dependencies = new ArrayList<>();
      Matcher dependency = DEPENDENCY.matcher(dependencyField);
      while (dependency.find()) {
        dependencies.add(dependency.group(1));
      }
      assertEquals(dependencies.size(), new HashSet<>(dependencies).size(),
          filename + " duplicate dependency");
      assertFalse(proposals.containsKey(id), "duplicate WIP-" + id);
      proposals.put(id, new Proposal(id, filename, status.group(1), List.copyOf(dependencies)));
    }
    assertFalse(proposals.isEmpty(), "proposal set");
    return proposals;
  }

  private static Map<String, IndexEntry> loadIndex() throws IOException {
    String source = Files.readString(ROOT.resolve("index.mdx"));
    Matcher row = INDEX_ROW.matcher(source);
    Map<String, IndexEntry> indexed = new LinkedHashMap<>();
    String previous = null;
    while (row.find()) {
      String id = row.group(1);
      if (previous != null) {
        assertTrue(previous.compareTo(id) < 0, "proposal index order");
      }
      assertFalse(indexed.containsKey(id), "duplicate indexed WIP-" + id);
      indexed.put(id, new IndexEntry(row.group(2), row.group(3)));
      previous = id;
    }
    return indexed;
  }

  private static String metadataValue(String source, String field) {
    Pattern pattern = Pattern.compile(
        "(?m)^\\| " + Pattern.quote(field) + " \\| (.+) \\|$");
    Matcher matcher = pattern.matcher(source);
    assertTrue(matcher.find(), field + " metadata");
    return matcher.group(1);
  }

  private static void visit(
      String id,
      Map<String, Proposal> proposals,
      Set<String> active,
      Set<String> complete) {
    if (complete.contains(id)) {
      return;
    }
    assertTrue(active.add(id), "WIP dependency cycle at WIP-" + id);
    for (String dependency : proposals.get(id).dependencies()) {
      visit(dependency, proposals, active, complete);
    }
    active.remove(id);
    complete.add(id);
  }
}
