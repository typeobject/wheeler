package com.typeobject.wheeler.runtime.hybrid;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

/** Bounded adaptive execution whose accepted observations can be replayed without effects. */
public final class AdaptiveReplayTree {
  /** Maximum number of nodes and decisions in one tree. */
  public static final int MAX_NODES = 64;

  private static final String LINEAGE_DOMAIN = "wheeler.adaptive-lineage.v1";
  private static final String PLAN_DOMAIN = "wheeler.adaptive-plan.v1";
  private static final String RUN_DOMAIN = "wheeler.adaptive-run.v1";

  private AdaptiveReplayTree() {}

  /** Semantic kind of one canonical tree node. */
  public enum NodeKind {
    /** Selects the lower child when the observation is below {@link Node#value()}. */
    DECISION,
    /** Publishes {@link Node#value()} without requesting another observation. */
    TERMINAL
  }

  /** One source-ordered tree node. Decision children must point strictly forward. */
  public record Node(int id, NodeKind kind, long value, int lowerChild, int upperChild) {
    /** Validates nonstructural fields before the containing plan validates graph edges. */
    public Node {
      Objects.requireNonNull(kind, "kind");
      if (id < 0 || MAX_NODES <= id) {
        throw new IllegalArgumentException("node id is outside the adaptive bound");
      }
      if (kind == NodeKind.TERMINAL && (lowerChild != -1 || upperChild != -1)) {
        throw new IllegalArgumentException("terminal node has a child");
      }
    }
  }

  /** Content-identified value returned by one live observation boundary. */
  public record ObservedValue(long value, String evidenceIdentity) {
    /** Requires one canonical SHA-256 evidence identity. */
    public ObservedValue {
      requireIdentity(evidenceIdentity, "evidence identity");
    }
  }

  /** Accepted observation and the exact branch selected from it. */
  public record Observation(
      int ordinal, int nodeId, long value, int selectedChild, String evidenceIdentity) {
    /** Requires bounded coordinates and one canonical evidence identity. */
    public Observation {
      if (ordinal < 0 || MAX_NODES <= ordinal) {
        throw new IllegalArgumentException("observation ordinal is outside the adaptive bound");
      }
      if (nodeId < 0 || MAX_NODES <= nodeId) {
        throw new IllegalArgumentException("observation node is outside the adaptive bound");
      }
      requireIdentity(evidenceIdentity, "evidence identity");
    }
  }

  /** Effect boundary used only by fresh execution, never by replay. */
  @FunctionalInterface
  public interface ObservationSource {
    /** Obtains one content-identified value for the exact lineage, node, and ordinal. */
    ObservedValue observe(String lineageIdentity, int nodeId, int ordinal);
  }

  /** Immutable validated adaptive plan with a canonical content identity. */
  public static final class Plan {
    private final List<Node> nodes;
    private final String identity;

    /** Validates one complete, forward-only, rooted tree and derives its identity. */
    public Plan(List<Node> nodes) {
      Objects.requireNonNull(nodes, "nodes");
      if (nodes.isEmpty() || MAX_NODES < nodes.size()) {
        throw new IllegalArgumentException("adaptive plan must contain one to 64 nodes");
      }
      this.nodes = List.copyOf(nodes);
      validateNodes(this.nodes);
      this.identity = planIdentity(this.nodes);
    }

    /** Returns the canonical source-ordered nodes. */
    public List<Node> nodes() {
      return nodes;
    }

    /** Returns the canonical SHA-256 plan identity. */
    public String identity() {
      return identity;
    }

    private static void validateNodes(List<Node> nodes) {
      boolean[] reached = new boolean[nodes.size()];
      int[] parentCounts = new int[nodes.size()];
      reached[0] = true;
      int terminals = 0;
      for (int index = 0; index < nodes.size(); index++) {
        Node node = nodes.get(index);
        if (node.id() != index) {
          throw new IllegalArgumentException("adaptive nodes are not in canonical id order");
        }
        if (!reached[index]) {
          throw new IllegalArgumentException("adaptive plan contains an unreachable node");
        }
        if (node.kind() == NodeKind.TERMINAL) {
          terminals++;
          continue;
        }
        requireForwardChild(node.lowerChild(), index, nodes.size());
        requireForwardChild(node.upperChild(), index, nodes.size());
        if (node.lowerChild() == node.upperChild()) {
          throw new IllegalArgumentException("adaptive decision has duplicate children");
        }
        reached[node.lowerChild()] = true;
        reached[node.upperChild()] = true;
        parentCounts[node.lowerChild()]++;
        parentCounts[node.upperChild()]++;
        if (parentCounts[node.lowerChild()] != 1
            || parentCounts[node.upperChild()] != 1) {
          throw new IllegalArgumentException("adaptive node has more than one parent");
        }
      }
      if (terminals == 0) {
        throw new IllegalArgumentException("adaptive plan has no terminal node");
      }
    }

    private static void requireForwardChild(int child, int parent, int nodeCount) {
      if (child <= parent || nodeCount <= child) {
        throw new IllegalArgumentException("adaptive decision child is not a forward node");
      }
    }
  }

  /** Complete immutable evidence needed to replay one selected decision path. */
  public record RunSnapshot(
      String planIdentity,
      String lineageIdentity,
      List<Observation> observations,
      int terminalNode,
      long result,
      String identity) {
    /** Defensively copies observations and requires canonical content identities. */
    public RunSnapshot {
      requireIdentity(planIdentity, "plan identity");
      requireIdentity(lineageIdentity, "lineage identity");
      observations = List.copyOf(Objects.requireNonNull(observations, "observations"));
      if (MAX_NODES < observations.size()) {
        throw new IllegalArgumentException("adaptive observation count exceeds the bound");
      }
      if (terminalNode < 0 || MAX_NODES <= terminalNode) {
        throw new IllegalArgumentException("terminal node is outside the adaptive bound");
      }
      requireIdentity(identity, "run identity");
    }
  }

  /** Executes one fresh lineage and records only the observations on its selected path. */
  public static RunSnapshot execute(
      Plan plan, String lineageIdentity, ObservationSource source) {
    Objects.requireNonNull(source, "source");
    return evaluate(plan, lineageIdentity, null, source);
  }

  /** Replays one accepted path without accepting or invoking an observation source. */
  public static RunSnapshot replay(Plan plan, RunSnapshot recorded) {
    Objects.requireNonNull(recorded, "recorded");
    if (!plan.identity().equals(recorded.planIdentity())) {
      throw new IllegalArgumentException("adaptive replay plan identity changed");
    }
    RunSnapshot replayed = evaluate(plan, recorded.lineageIdentity(), recorded, null);
    if (!replayed.equals(recorded)) {
      throw new IllegalArgumentException("adaptive replay record is noncanonical");
    }
    return replayed;
  }

  /** Derives a deterministic fresh lineage from one parent identity and retry ordinal. */
  public static String retryLineage(String parentLineageIdentity, int retryOrdinal) {
    requireIdentity(parentLineageIdentity, "parent lineage identity");
    if (retryOrdinal < 1 || MAX_NODES < retryOrdinal) {
      throw new IllegalArgumentException("retry ordinal must be between one and 64");
    }
    MessageDigest digest = sha256();
    updateText(digest, LINEAGE_DOMAIN);
    updateIdentity(digest, parentLineageIdentity);
    updateInt(digest, retryOrdinal);
    return HexFormat.of().formatHex(digest.digest());
  }

  private static RunSnapshot evaluate(
      Plan plan,
      String lineageIdentity,
      RunSnapshot recorded,
      ObservationSource source) {
    Objects.requireNonNull(plan, "plan");
    requireIdentity(lineageIdentity, "lineage identity");
    List<Observation> observations = new ArrayList<>();
    int nodeId = 0;
    int ordinal = 0;
    while (true) {
      if (MAX_NODES <= ordinal) {
        throw new IllegalArgumentException("adaptive path exceeds the decision bound");
      }
      Node node = plan.nodes().get(nodeId);
      if (node.kind() == NodeKind.TERMINAL) {
        if (recorded != null && ordinal != recorded.observations().size()) {
          throw new IllegalArgumentException("adaptive replay contains trailing observations");
        }
        String identity = runIdentity(
            plan.identity(), lineageIdentity, observations, nodeId, node.value());
        RunSnapshot result = new RunSnapshot(
            plan.identity(), lineageIdentity, observations, nodeId, node.value(), identity);
        if (recorded != null && !identity.equals(recorded.identity())) {
          throw new IllegalArgumentException("adaptive replay identity changed");
        }
        return result;
      }

      Observation accepted;
      if (recorded == null) {
        ObservedValue value = Objects.requireNonNull(
            source.observe(lineageIdentity, nodeId, ordinal), "observed value");
        int child = value.value() < node.value() ? node.lowerChild() : node.upperChild();
        accepted = new Observation(
            ordinal, nodeId, value.value(), child, value.evidenceIdentity());
      } else {
        if (recorded.observations().size() <= ordinal) {
          throw new IllegalArgumentException("adaptive replay lacks a decision observation");
        }
        accepted = recorded.observations().get(ordinal);
        if (accepted.ordinal() != ordinal || accepted.nodeId() != nodeId) {
          throw new IllegalArgumentException("adaptive replay path coordinate changed");
        }
        int child = accepted.value() < node.value()
            ? node.lowerChild() : node.upperChild();
        if (accepted.selectedChild() != child) {
          throw new IllegalArgumentException("adaptive replay branch changed");
        }
      }

      observations.add(accepted);
      nodeId = accepted.selectedChild();
      ordinal++;
    }
  }

  private static String planIdentity(List<Node> nodes) {
    MessageDigest digest = sha256();
    updateText(digest, PLAN_DOMAIN);
    updateInt(digest, nodes.size());
    for (Node node : nodes) {
      updateInt(digest, node.id());
      updateInt(digest, node.kind().ordinal());
      updateLong(digest, node.value());
      updateInt(digest, node.lowerChild());
      updateInt(digest, node.upperChild());
    }
    return HexFormat.of().formatHex(digest.digest());
  }

  private static String runIdentity(
      String planIdentity,
      String lineageIdentity,
      List<Observation> observations,
      int terminalNode,
      long result) {
    MessageDigest digest = sha256();
    updateText(digest, RUN_DOMAIN);
    updateIdentity(digest, planIdentity);
    updateIdentity(digest, lineageIdentity);
    updateInt(digest, observations.size());
    for (Observation observation : observations) {
      updateInt(digest, observation.ordinal());
      updateInt(digest, observation.nodeId());
      updateLong(digest, observation.value());
      updateInt(digest, observation.selectedChild());
      updateIdentity(digest, observation.evidenceIdentity());
    }
    updateInt(digest, terminalNode);
    updateLong(digest, result);
    return HexFormat.of().formatHex(digest.digest());
  }

  private static void requireIdentity(String identity, String field) {
    Objects.requireNonNull(identity, field);
    if (!identity.matches("[0-9a-f]{64}")) {
      throw new IllegalArgumentException(field + " must be lowercase SHA-256");
    }
  }

  private static MessageDigest sha256() {
    try {
      return MessageDigest.getInstance("SHA-256");
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void updateIdentity(MessageDigest digest, String identity) {
    digest.update(HexFormat.of().parseHex(identity));
  }

  private static void updateText(MessageDigest digest, String value) {
    byte[] encoded = value.getBytes(StandardCharsets.US_ASCII);
    updateInt(digest, encoded.length);
    digest.update(encoded);
  }

  private static void updateInt(MessageDigest digest, int value) {
    digest.update(ByteBuffer.allocate(Integer.BYTES).putInt(value).array());
  }

  private static void updateLong(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(Long.BYTES).putLong(value).array());
  }
}
