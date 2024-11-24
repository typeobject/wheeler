package com.typeobject.wheeler.core.history;

import com.typeobject.wheeler.core.exceptions.NoHistoryException;
import com.typeobject.wheeler.core.thread.WheelerThreadState;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class ExecutionHistory {
  private final Map<Long, Deque<HistoryEntry>> threadHistory = new ConcurrentHashMap<>();
  private final ReentrantReadWriteLock lock = new ReentrantReadWriteLock();

  public void recordState(long threadId, WheelerThreadState state) {
    Lock writeLock = lock.writeLock();
    writeLock.lock();
    try {
      Deque<HistoryEntry> history =
              threadHistory.computeIfAbsent(threadId, k -> new ConcurrentLinkedDeque<>());
      history.push(new StateHistoryEntry(state));
    } finally {
      writeLock.unlock();
    }
  }

  public WheelerThreadState getLastState(long threadId) {
    Lock readLock = lock.readLock();
    readLock.lock();
    try {
      Deque<HistoryEntry> history = threadHistory.get(threadId);
      if (history == null || history.isEmpty()) {
        throw new NoHistoryException("No history available for thread " + threadId);
      }

      // Keep popping until we find a state entry
      while (!history.isEmpty()) {
        HistoryEntry entry = history.pop();
        if (entry instanceof StateHistoryEntry) {
          return ((StateHistoryEntry) entry).getState();
        }
      }
      throw new NoHistoryException("No state found in history for thread " + threadId);
    } finally {
      readLock.unlock();
    }
  }

  public void pushHistoryMarker(long threadId, String marker) {
    Lock writeLock = lock.writeLock();
    writeLock.lock();
    try {
      Deque<HistoryEntry> history =
              threadHistory.computeIfAbsent(threadId, k -> new ConcurrentLinkedDeque<>());
      history.push(new MarkerHistoryEntry(marker));
    } finally {
      writeLock.unlock();
    }
  }

  public void revertToMarker(long threadId, String marker) {
    Lock writeLock = lock.writeLock();
    writeLock.lock();
    try {
      Deque<HistoryEntry> history = threadHistory.get(threadId);
      if (history == null) {
        throw new NoHistoryException("No history for thread " + threadId);
      }

      // Pop entries until we find the marker
      while (!history.isEmpty()) {
        HistoryEntry entry = history.peek();
        if (entry instanceof MarkerHistoryEntry &&
                ((MarkerHistoryEntry) entry).getMarker().equals(marker)) {
          return;
        }
        history.pop();
      }
      throw new NoHistoryException("Marker not found: " + marker);
    } finally {
      writeLock.unlock();
    }
  }

  private abstract static class HistoryEntry {
    private final long timestamp;

    protected HistoryEntry() {
      this.timestamp = System.nanoTime();
    }

    @SuppressWarnings("unused")
    public long getTimestamp() {
      return timestamp;
    }
  }

  private static class StateHistoryEntry extends HistoryEntry {
    private final WheelerThreadState state;

    public StateHistoryEntry(WheelerThreadState state) {
      super();
      this.state = state;
    }

    public WheelerThreadState getState() {
      return state;
    }
  }

  private static class MarkerHistoryEntry extends HistoryEntry {
    private final String marker;

    public MarkerHistoryEntry(String marker) {
      super();
      this.marker = marker;
    }

    public String getMarker() {
      return marker;
    }
  }
}