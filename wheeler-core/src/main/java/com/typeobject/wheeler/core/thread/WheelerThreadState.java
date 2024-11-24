// WheelerThreadState.java
package com.typeobject.wheeler.core.thread;

import org.checkerframework.checker.nullness.qual.Nullable;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class WheelerThreadState implements Cloneable {
  private final long id;
  private final long pc;
  private final Deque<Long> stack;
  private final Deque<Long> historyStack;
  private final Map<Long, Long> localStorage;
  private final WheelerThreadStatus status;

  public WheelerThreadState(WheelerThread thread) {
    this.id = thread.getId();
    this.pc = thread.getPc();
    this.stack = new ArrayDeque<>(thread.getStack());
    this.historyStack = new ArrayDeque<>(thread.getHistoryStack());
    this.localStorage = new HashMap<>(thread.getLocalStorage());
    this.status = thread.getStatus();
  }

  private WheelerThreadState(
          long id,
          long pc,
          Deque<Long> stack,
          Deque<Long> historyStack,
          Map<Long, Long> localStorage,
          WheelerThreadStatus status) {
    this.id = id;
    this.pc = pc;
    this.stack = stack;
    this.historyStack = historyStack;
    this.localStorage = localStorage;
    this.status = status;
  }

  public long getId() {
    return id;
  }

  public long getPc() {
    return pc;
  }

  public Deque<Long> getStack() {
    return stack;
  }

  public Deque<Long> getHistoryStack() {
    return historyStack;
  }

  public Map<Long, Long> getLocalStorage() {
    return localStorage;
  }

  public WheelerThreadStatus getStatus() {
    return status;
  }

  @Override
  public WheelerThreadState clone() {
    Deque<Long> stackCopy = new ArrayDeque<>(stack);
    Deque<Long> historyStackCopy = new ArrayDeque<>(historyStack);
    Map<Long, Long> localStorageCopy = new HashMap<>(localStorage);

    return new WheelerThreadState(id, pc, stackCopy, historyStackCopy, localStorageCopy, status);
  }

  @Override
  public boolean equals(@Nullable Object o) {
    if (this == o) return true;
    if (!(o instanceof WheelerThreadState)) return false;
    WheelerThreadState that = (WheelerThreadState) o;
    return id == that.id
            && pc == that.pc
            && stack.equals(that.stack)
            && historyStack.equals(that.historyStack)
            && localStorage.equals(that.localStorage)
            && status == that.status;
  }

  @Override
  public int hashCode() {
    return Objects.hash(id, pc, stack, historyStack, localStorage, status);
  }
}