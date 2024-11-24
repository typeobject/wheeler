package com.typeobject.wheeler.core.thread;

import com.typeobject.wheeler.core.instruction.WheelerThreadStatus;
import com.typeobject.wheeler.core.instruction.WheelerThread;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Stack;


public class WheelerThreadState implements Cloneable {
    private final long id;
    private final long pc;
    private final Stack<Long> stack;
    private final Stack<Long> historyStack;
    private final Map<Long, Long> localStorage;
    private final WheelerThreadStatus status;

    public WheelerThreadState(WheelerThread thread) {
        this.id = thread.getId();
        this.pc = thread.getPc();
        this.stack = new Stack<>();
        this.stack.addAll(thread.getStack());
        this.historyStack = new Stack<>();
        this.historyStack.addAll(thread.getHistoryStack());
        this.localStorage = new HashMap<>(thread.getLocalStorage());
        this.status = thread.getStatus();
    }

    private WheelerThreadState(long id, long pc, Stack<Long> stack,
                        Stack<Long> historyStack,
                        Map<Long, Long> localStorage,
                        WheelerThreadStatus status) {
        this.id = id;
        this.pc = pc;
        this.stack = stack;
        this.historyStack = historyStack;
        this.localStorage = localStorage;
        this.status = status;
    }

    public long getId() { return id; }
    public long getPc() { return pc; }
    public Stack<Long> getStack() { return stack; }
    public Stack<Long> getHistoryStack() { return historyStack; }
    public Map<Long, Long> getLocalStorage() { return localStorage; }
    public WheelerThreadStatus getStatus() { return status; }

    @Override
    public WheelerThreadState clone() {
        Stack<Long> stackCopy = new Stack<>();
        stackCopy.addAll(stack);
        Stack<Long> historyStackCopy = new Stack<>();
        historyStackCopy.addAll(historyStack);
        Map<Long, Long> localStorageCopy = new HashMap<>(localStorage);

        return new WheelerThreadState(id, pc, stackCopy, historyStackCopy,
                localStorageCopy, status);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof WheelerThreadState)) return false;
        WheelerThreadState that = (WheelerThreadState) o;
        return id == that.id &&
                pc == that.pc &&
                stack.equals(that.stack) &&
                historyStack.equals(that.historyStack) &&
                localStorage.equals(that.localStorage) &&
                status == that.status;
    }

    @Override
    public int hashCode() {
        return  Objects.hash(id, pc, stack, historyStack, localStorage, status);
    }
}