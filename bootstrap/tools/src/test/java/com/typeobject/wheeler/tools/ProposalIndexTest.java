package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Checks proposal navigation, lifecycle metadata, and reviewable progress records. */
final class ProposalIndexTest {
  private static final Path ROOT = Path.of("docs/internal/proposals");
  private static final Pattern FILE = Pattern.compile("WIP-(\\d{4})-[a-z0-9-]+\\.md");
  private static final Pattern HEADING = Pattern.compile("# WIP-(\\d{4}): (.+)");
  private static final Pattern REFERENCE = Pattern.compile("WIP-(\\d{4})");
  private static final Pattern FIELD = Pattern.compile("\\| ([^|]+) \\| ([^|]+) \\|");
  private static final Pattern CATALOG = Pattern.compile(
      "\\[[^]\\n]+]\\((catalog/[a-z-]+\\.md)\\)");
  private static final Pattern ROW = Pattern.compile(
      "(?m)^\\| \\[WIP-(\\d{4})]\\(([^)]+)\\) \\| (.+) \\|$");
  private static final Set<String> STATUSES = Set.of(
      "Draft", "Review", "Accepted", "Implementing", "Implemented", "Superseded", "Withdrawn");
  private static final Set<String> OPEN = Set.of("Draft", "Review", "Accepted", "Implementing");
  private static final List<String> FIELDS = List.of(
      "Status", "Owners", "Created", "Updated", "Area", "Depends on", "Supersedes", "Superseded by");
  private static final int MAX_PARAGRAPH_CHARACTERS = 2_000;

  private record Proposal(
      String id, String filename, String title, Map<String, String> metadata, String source) {
    String status() {
      return metadata.get("Status");
    }
  }

  private record IndexEntry(String target, String description) {}

  @Test
  void catalogsNameEveryProposalOnceWithExactTitleAndStatus() throws Exception {
    Map<String, Proposal> proposals = loadProposals();
    List<Path> catalogs = catalogs();
    Map<String, IndexEntry> indexed = new LinkedHashMap<>();
    for (Path catalog : catalogs) {
      Map<String, IndexEntry> entries = indexRows(Files.readString(catalog));
      assertFalse(entries.isEmpty(), catalog.toString());
      assertEquals(entries.keySet().stream().sorted().toList(),
          List.copyOf(entries.keySet()), catalog + " numeric order");
      for (var entry : entries.entrySet()) {
        assertFalse(indexed.containsKey(entry.getKey()), "duplicate catalog WIP-" + entry.getKey());
        indexed.put(entry.getKey(), entry.getValue());
      }
    }

    assertEquals(proposals.keySet(), indexed.keySet(), "catalog proposal IDs");
    for (Proposal proposal : proposals.values()) {
      IndexEntry entry = indexed.get(proposal.id());
      assertEquals("../" + proposal.filename(), entry.target(), proposal.id());
      assertEquals(proposal.status() + " | " + proposal.title(), entry.description(), proposal.id());
    }
  }

  @Test
  void roadmapNamesEveryOpenContractWithoutRepeatingStatuses() throws Exception {
    Map<String, Proposal> proposals = loadProposals();
    Map<String, IndexEntry> roadmap = indexRows(Files.readString(ROOT.resolve("roadmap.md")));
    Set<String> open = new HashSet<>();
    for (Proposal proposal : proposals.values()) {
      if (OPEN.contains(proposal.status())) {
        open.add(proposal.id());
      }
    }
    assertEquals(open, roadmap.keySet(), "roadmap open proposal IDs");
    for (var entry : roadmap.entrySet()) {
      assertEquals(proposals.get(entry.getKey()).filename(), entry.getValue().target());
      assertFalse(entry.getValue().description().contains(" | "), "one remaining-gate column");
    }
  }

  @Test
  void dependenciesAndWholeContractReplacementsRemainClosedAndAcyclic() throws Exception {
    Map<String, Proposal> proposals = loadProposals();
    for (Proposal proposal : proposals.values()) {
      for (String id : references(proposal.source())) {
        assertTrue(proposals.containsKey(id), proposal.id() + " references missing WIP-" + id);
      }
      List<String> dependencies = references(proposal.metadata().get("Depends on"));
      assertEquals(dependencies.size(), new HashSet<>(dependencies).size(),
          proposal.id() + " duplicate dependency");
      String replacement = proposal.metadata().get("Superseded by");
      if (proposal.status().equals("Superseded")) {
        List<String> replacements = references(replacement);
        assertFalse(replacements.isEmpty(), proposal.id() + " replacement ID");
        for (String id : replacements) {
          assertTrue(references(proposals.get(id).metadata().get("Supersedes"))
              .contains(proposal.id()), proposal.id() + " replacement must link back");
        }
      } else {
        assertEquals("None", replacement, proposal.id() + " use Follow-up for scoped changes");
      }
    }
    for (String field : List.of("Depends on", "Superseded by")) {
      Set<String> complete = new HashSet<>();
      for (String id : proposals.keySet()) {
        visit(id, field, proposals, new HashSet<>(), complete);
      }
    }
  }

  @Test
  void metadataRejectsMissingDuplicateAndBackdatedFields() {
    String source = "# WIP-0001: Fixture\n\n"
        + "| Status | Draft |\n| Owners | Maintainers |\n"
        + "| Created | 2026-08-01 |\n| Updated | 2026-08-02 |\n"
        + "| Area | Tests |\n| Depends on | None |\n"
        + "| Supersedes | None |\n| Superseded by | None |\n";
    String filename = "WIP-0001-fixture.md";
    assertEquals("Fixture", proposal(filename, source).title());
    assertEquals("Fixture", proposal(filename,
        source + "\nAn example table follows.\n\n| Area | Unrelated data |\n").title());
    assertEquals("WIP-0002", proposal(filename,
        source + "| Follow-up | WIP-0002 |\n").metadata().get("Follow-up"));
    assertThrows(AssertionError.class,
        () -> proposal(filename, source.replace("| Depends on | None |\n", "")));
    assertThrows(AssertionError.class,
        () -> proposal(filename, source + "| Status | Implemented |\n"));
    assertThrows(AssertionError.class,
        () -> proposal(filename, source.replace("2026-08-02", "2026-07-31")));
    assertThrows(AssertionError.class, () -> proposal(filename,
        source + "| Follow-up | WIP-0002 |\n| Follow-up | WIP-0003 |\n"));
    assertThrows(AssertionError.class, () -> proposal(filename,
        source + "| Follow-ups | WIP-0002 |\n"));
  }

  @Test
  void indexRejectsDuplicateIdsEvenWhenTheTargetsDiffer() {
    assertThrows(AssertionError.class, () -> indexRows(
        "| [WIP-0001](WIP-0001-first.md) | Draft | First |\n"
            + "| [WIP-0001](WIP-0001-second.md) | Draft | Second |\n"));
  }

  @Test
  void proposalProseStaysWithinReviewableParagraphsAndFiles() throws Exception {
    List<String> failures = new ArrayList<>();
    try (var paths = Files.walk(ROOT)) {
      for (Path path : paths.filter(Files::isRegularFile).sorted().toList()) {
        String source = Files.readString(path);
        assertTrue(source.lines().count() < 1_000, path + " line limit");
        for (int line : oversizedParagraphs(source)) {
          failures.add(path + ":" + line + ": split or consolidate the prose paragraph");
        }
      }
    }
    assertEquals(List.of(), failures);
  }

  @Test
  void paragraphCheckCountsWrappedProseButNotCodeOrTables() {
    String line = "A".repeat(1_100);
    assertEquals(List.of(1), oversizedParagraphs(line + "\n" + line + "\n"));
    assertEquals(List.of(), oversizedParagraphs(line + "\n\n" + line));
    assertEquals(List.of(), oversizedParagraphs("- " + line + "\n- " + line));
    assertEquals(List.of(), oversizedParagraphs("```text\n" + line + line + "\n```\n"));
    assertEquals(List.of(), oversizedParagraphs("| " + line + line + " |\n"));
  }

  private static Map<String, Proposal> loadProposals() throws IOException {
    List<Path> files;
    try (var paths = Files.list(ROOT)) {
      files = paths.filter(Files::isRegularFile)
          .filter(path -> path.getFileName().toString().startsWith("WIP-"))
          .sorted().toList();
    }
    Map<String, Proposal> result = new LinkedHashMap<>();
    for (Path path : files) {
      Proposal proposal = proposal(path.getFileName().toString(), Files.readString(path));
      assertFalse(result.containsKey(proposal.id()), "duplicate WIP-" + proposal.id());
      result.put(proposal.id(), proposal);
    }
    assertFalse(result.isEmpty(), "proposal set");
    return result;
  }

  private static Proposal proposal(String filename, String source) {
    Matcher file = FILE.matcher(filename);
    assertTrue(file.matches(), filename + " filename");
    Matcher heading = HEADING.matcher(source.lines().findFirst().orElseThrow());
    assertTrue(heading.matches(), filename + " heading");
    assertEquals(file.group(1), heading.group(1), filename + " heading ID");
    Map<String, String> metadata = metadata(source, filename);
    assertTrue(STATUSES.contains(metadata.get("Status")), filename + " status vocabulary");
    LocalDate created = date(metadata.get("Created"), filename);
    LocalDate updated = date(metadata.get("Updated"), filename);
    assertFalse(updated.isBefore(created), filename + " update precedes creation");
    return new Proposal(file.group(1), filename, heading.group(2), Map.copyOf(metadata), source);
  }

  private static LocalDate date(String text, String filename) {
    assertTrue(text.matches("\\d{4}-\\d{2}-\\d{2}"), filename + " ISO date");
    return LocalDate.parse(text);
  }

  private static List<Path> catalogs() throws IOException {
    Matcher links = CATALOG.matcher(Files.readString(ROOT.resolve("index.mdx")));
    List<Path> linked = new ArrayList<>();
    while (links.find()) {
      Path path = ROOT.resolve(links.group(1));
      assertFalse(linked.contains(path), "duplicate catalog link " + path);
      linked.add(path);
    }
    try (var paths = Files.list(ROOT.resolve("catalog"))) {
      assertEquals(paths.filter(Files::isRegularFile).sorted().toList(),
          linked.stream().sorted().toList(), "catalog navigation");
    }
    assertFalse(linked.isEmpty(), "catalog navigation");
    return linked;
  }

  private static Map<String, IndexEntry> indexRows(String source) {
    Matcher row = ROW.matcher(source);
    Map<String, IndexEntry> result = new LinkedHashMap<>();
    while (row.find()) {
      String id = row.group(1);
      assertFalse(result.containsKey(id), "duplicate indexed WIP-" + id);
      result.put(id, new IndexEntry(row.group(2), row.group(3)));
    }
    return result;
  }

  private static Map<String, String> metadata(String source, String filename) {
    List<String> rows = source.lines().dropWhile(line -> !line.startsWith("|"))
        .takeWhile(line -> line.startsWith("|")).toList();
    Map<String, String> values = new LinkedHashMap<>();
    for (String row : rows) {
      if (row.equals("| Field | Value |") || row.equals("| --- | --- |")) {
        continue;
      }
      Matcher field = FIELD.matcher(row);
      assertTrue(field.matches(), filename + " malformed metadata row: " + row);
      String name = field.group(1);
      String value = field.group(2);
      assertTrue(FIELDS.contains(name) || name.equals("Follow-up"),
          filename + " unknown metadata field: " + name);
      assertFalse(value.isBlank(), filename + " empty " + name);
      assertFalse(values.containsKey(name), filename + " duplicate " + name);
      values.put(name, value);
    }
    for (String field : FIELDS) {
      assertTrue(values.containsKey(field), filename + " missing " + field);
    }
    return values;
  }

  private static List<String> references(String source) {
    List<String> result = new ArrayList<>();
    Matcher reference = REFERENCE.matcher(source);
    while (reference.find()) {
      result.add(reference.group(1));
    }
    return result;
  }

  private static void visit(
      String id,
      String field,
      Map<String, Proposal> proposals,
      Set<String> active,
      Set<String> complete) {
    if (complete.contains(id)) {
      return;
    }
    assertTrue(active.add(id), field + " cycle at WIP-" + id);
    for (String next : references(proposals.get(id).metadata().get(field))) {
      visit(next, field, proposals, active, complete);
    }
    active.remove(id);
    complete.add(id);
  }

  private static List<Integer> oversizedParagraphs(String source) {
    List<Integer> failures = new ArrayList<>();
    boolean fenced = false;
    int start = 0;
    int length = 0;
    String[] lines = (source + "\n").split("\\R", -1);
    for (int index = 0; index < lines.length; index++) {
      String line = lines[index].strip();
      boolean fence = line.startsWith("```");
      boolean boundary = line.isEmpty() || line.startsWith("#") || line.startsWith("|")
          || line.startsWith(">") || line.matches("(?:[-*+] |\\d+\\. ).*");
      if (fence || (!fenced && boundary)) {
        if (length > MAX_PARAGRAPH_CHARACTERS) {
          failures.add(start);
        }
        length = 0;
      }
      if (fence) {
        fenced = !fenced;
      } else if (!fenced && !line.isEmpty()
          && !line.startsWith("#") && !line.startsWith("|") && !line.startsWith(">")) {
        if (length == 0) {
          start = index + 1;
        } else {
          length += 1;
        }
        length += line.length();
      }
    }
    return failures;
  }
}
