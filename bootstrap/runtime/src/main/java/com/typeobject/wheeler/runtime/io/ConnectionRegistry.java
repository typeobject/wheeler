package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Primitive-table connection admission with no per-dormant-connection execution resource. */
public final class ConnectionRegistry {
  private static final int MAX_CONNECTIONS = 1_000_000;
  private static final byte FREE = 0;
  private static final byte DORMANT = 1;
  private static final byte ACTIVE = 2;

  /** Generation-checked affine connection authority. */
  public static final class Connection {
    private final ConnectionRegistry owner;
    private final int slot;
    private final int generation;

    private Connection(ConnectionRegistry owner, int slot, int generation) {
      this.owner = owner;
      this.slot = slot;
      this.generation = generation;
    }

    /** Returns the stable slot within this registry. */
    public int slot() {
      return slot;
    }

    /** Returns the generation that prevents stale reuse. */
    public int generation() {
      return generation;
    }
  }

  private final byte[] states;
  private final int[] generations;
  private final int[] freeSlots;
  private final int maxActive;
  private int freeCount;
  private int openCount;
  private int activeCount;

  /** Creates one fixed registry with a separate active-work credit bound. */
  public ConnectionRegistry(int maxConnections, int maxActive) {
    if (maxConnections < 1 || maxConnections > MAX_CONNECTIONS) {
      throw new IllegalArgumentException("connection capacity must be between 1 and 1000000");
    }
    if (maxActive < 1 || maxActive > maxConnections) {
      throw new IllegalArgumentException("active capacity must fit connection capacity");
    }
    states = new byte[maxConnections];
    generations = new int[maxConnections];
    freeSlots = new int[maxConnections];
    for (int slot = 0; slot < maxConnections; slot++) {
      generations[slot] = 1;
      freeSlots[maxConnections - slot - 1] = slot;
    }
    freeCount = maxConnections;
    this.maxActive = maxActive;
  }

  /** Opens one stack-ordered available slot in a dormant state. */
  public synchronized Connection open() {
    if (freeCount == 0) {
      throw new IllegalStateException("connection capacity exhausted");
    }
    int slot = freeSlots[--freeCount];
    if (states[slot] != FREE) {
      throw new IllegalStateException("connection free table is corrupt");
    }
    states[slot] = DORMANT;
    openCount++;
    return new Connection(this, slot, generations[slot]);
  }

  /** Acquires one active-work credit without allocating execution machinery. */
  public synchronized void activate(Connection connection) {
    int slot = validate(connection);
    if (states[slot] != DORMANT) {
      throw new IllegalStateException("connection is not dormant");
    }
    if (activeCount == maxActive) {
      throw new IllegalStateException("active connection credit exhausted");
    }
    states[slot] = ACTIVE;
    activeCount++;
  }

  /** Returns an active connection to dormant storage. */
  public synchronized void park(Connection connection) {
    int slot = validate(connection);
    if (states[slot] != ACTIVE) {
      throw new IllegalStateException("connection is not active");
    }
    states[slot] = DORMANT;
    activeCount--;
  }

  /** Closes a dormant connection and invalidates its generation. */
  public synchronized void close(Connection connection) {
    int slot = validate(connection);
    if (states[slot] != DORMANT) {
      throw new IllegalStateException("only a dormant connection can close");
    }
    if (generations[slot] == Integer.MAX_VALUE) {
      throw new IllegalStateException("connection generation exhausted");
    }
    states[slot] = FREE;
    generations[slot]++;
    openCount--;
    freeSlots[freeCount++] = slot;
  }

  /** Returns the number of dormant and active connections. */
  public synchronized int openCount() {
    return openCount;
  }

  /** Returns the number currently holding active-work credit. */
  public synchronized int activeCount() {
    return activeCount;
  }

  /** Returns whether one live authority currently occupies dormant storage. */
  public synchronized boolean isDormant(Connection connection) {
    return states[validate(connection)] == DORMANT;
  }

  private int validate(Connection connection) {
    Objects.requireNonNull(connection, "connection");
    if (connection.owner != this) {
      throw new IllegalArgumentException("connection belongs to another registry");
    }
    int slot = connection.slot;
    if (slot < 0 || slot >= states.length
        || states[slot] == FREE
        || generations[slot] != connection.generation) {
      throw new IllegalStateException("connection authority is stale");
    }
    return slot;
  }
}
