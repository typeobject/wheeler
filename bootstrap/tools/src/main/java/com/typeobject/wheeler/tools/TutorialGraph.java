package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Validates the bounded ordered tutorial graph from parser-owned page metadata. */
final class TutorialGraph {
  private static final Pattern STEP_RANGE = Pattern.compile("T([0-9]{2})");
  private static final int FIRST_STEP = 0;
  private static final int LAST_STEP = 93;

  private TutorialGraph() {}

  static void validate(List<DocumentationMarkdown.Page> pages) {
    List<Node> nodes = pages.stream()
        .filter(page -> page.source().startsWith("tutorials/"))
        .filter(page -> !page.source().equals("tutorials/index.mdx"))
        .map(TutorialGraph::node)
        .sorted(Comparator.comparingInt(Node::order))
        .toList();
    if (nodes.isEmpty()) {
      return;
    }
    Set<String> identities = new HashSet<>();
    Set<Integer> orders = new HashSet<>();
    List<Integer> steps = new ArrayList<>();
    for (Node node : nodes) {
      if (!identities.add(node.identity())) {
        fail("Duplicate tutorial identity " + node.identity());
      }
      if (!orders.add(node.order())) {
        fail("Duplicate tutorial order " + node.order());
      }
      steps.addAll(node.steps());
    }
    for (int index = 0; index < nodes.size(); index++) {
      if (nodes.get(index).order() != index) {
        fail("Tutorial order must be contiguous at " + nodes.get(index).identity());
      }
    }
    if (steps.size() != LAST_STEP - FIRST_STEP + 1) {
      fail("Tutorial steps must cover T00 through T93 exactly");
    }
    for (int index = FIRST_STEP; index <= LAST_STEP; index++) {
      if (steps.get(index) != index) {
        fail("Tutorial step order disagrees at T%02d".formatted(index));
      }
    }
  }

  private static Node node(DocumentationMarkdown.Page page) {
    Map<String, String> metadata = page.metadata();
    String identity = required(metadata, "tutorial_id", page.source());
    String stepText = required(metadata, "tutorial_steps", page.source());
    String orderText = required(metadata, "tutorial_order", page.source());
    if (required(metadata, "tutorial_part", page.source()).isBlank()
        || required(metadata, "tutorial_kind", page.source()).isBlank()
        || required(metadata, "tutorial_source", page.source()).isBlank()
        || required(metadata, "tutorial_expectation", page.source()).isBlank()
        || required(metadata, "tutorial_evidence", page.source()).isBlank()) {
      fail("Tutorial metadata cannot be blank in " + page.source());
    }
    int order;
    try {
      order = Integer.parseInt(orderText);
    } catch (NumberFormatException exception) {
      throw new PackageFormatException("Invalid tutorial_order in " + page.source());
    }
    if (order < 0 || order > 1_000) {
      fail("Invalid tutorial_order in " + page.source());
    }
    List<Integer> steps = new ArrayList<>();
    for (String step : stepText.split(",", -1)) {
      Matcher matcher = STEP_RANGE.matcher(step);
      if (!matcher.matches()) {
        fail("Invalid tutorial step " + step + " in " + page.source());
      }
      steps.add(Integer.parseInt(matcher.group(1)));
    }
    if (steps.isEmpty()) {
      fail("Tutorial page has no steps: " + page.source());
    }
    return new Node(identity, order, List.copyOf(steps));
  }

  private static String required(Map<String, String> metadata, String field, String source) {
    String value = metadata.get(field);
    if (value == null) {
      fail("Missing " + field + " in " + source);
    }
    return value;
  }

  private static void fail(String message) {
    throw new PackageFormatException(message);
  }

  private record Node(String identity, int order, List<Integer> steps) {}
}
