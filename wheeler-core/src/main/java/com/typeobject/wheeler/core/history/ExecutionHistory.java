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
            Deque<HistoryEntry> history = threadHistory.computeIfAbsent(threadId,
                    k -> new ConcurrentLinkedDeque<>());
            history.push(new HistoryEntry(state));
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
            return history.pop().getState();
        } finally {
            readLock.unlock();
        }
    }

    public void pushHistoryMarker(long threadId, String marker) {
        recordState(threadId, new HistoryMarker(marker));
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
                if (entry instanceof HistoryMarker &&
                        ((HistoryMarker)entry).getMarker().equals(marker)) {
                    return;
                }
                history.pop();
            }
            throw new NoHistoryException("Marker not found: " + marker);
        } finally {
            writeLock.unlock();
        }
    }

    private static class HistoryEntry {
        private final WheelerThreadState state;
        private final long timestamp;

        public HistoryEntry(WheelerThreadState state) {
            this.state = state;
            this.timestamp = System.nanoTime();
        }

        public WheelerThreadState getState() {
            return state;
        }
    }

    private static class HistoryMarker extends HistoryEntry {
        private final String marker;

        public HistoryMarker(String marker) {
            super(null);
            this.marker = marker;
        }

        public String getMarker() {
            return marker;
        }
    }
}