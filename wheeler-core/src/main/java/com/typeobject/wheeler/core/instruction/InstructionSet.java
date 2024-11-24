package com.typeobject.wheeler.core.instruction;

import com.typeobject.wheeler.core.exceptions.InvalidInstructionException;
import com.typeobject.wheeler.core.instruction.handlers.IncrementHandler;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class InstructionSet {
  private static final Map<Byte, InstructionHandler> handlers = new ConcurrentHashMap<>();

  // Opcodes
  public static final byte PUSH = 0x01;
  public static final byte POP = 0x02;
  public static final byte SWAP = 0x03;
  public static final byte DUP = 0x04;

  public static final byte ADD = 0x10;
  public static final byte SUB = 0x11;
  public static final byte MUL = 0x12;
  public static final byte DIV = 0x13;
  public static final byte INC = 0x14;
  public static final byte DEC = 0x15;

  public static final byte LOAD = 0x20;
  public static final byte STORE = 0x21;
  public static final byte ALLOC = 0x22;
  public static final byte FREE = 0x23;

  public static final byte JUMP = 0x30;
  public static final byte BRANCH = 0x31;
  public static final byte CALL = 0x32;
  public static final byte RETURN = 0x33;

  public static final byte THNEW = 0x40;
  public static final byte THJOIN = 0x41;
  public static final byte THYIELD = 0x42;
  public static final byte THEXIT = 0x43;

  public static final byte LOCK = 0x50;
  public static final byte UNLOCK = 0x51;
  public static final byte BARRIER = 0x52;
  public static final byte FENCE = 0x53;

  public static final byte CHCREATE = 0x60;
  public static final byte CHSEND = 0x61;
  public static final byte CHRECV = 0x62;
  public static final byte CHCLOSE = 0x63;

  public static final byte TXBEGIN = 0x70;
  public static final byte TXCOMMIT = 0x71;
  public static final byte TXABORT = 0x72;
  public static final byte TXREAD = 0x73;
  public static final byte TXWRITE = 0x74;

  public static final byte HSAVE = (byte) 0x80;
  public static final byte HRESTORE = (byte) 0x81;
  public static final byte HGC = (byte) 0x82;
  public static final byte HQUERY = (byte) 0x83;

  public static final byte HADAMARD = (byte) 0x90;
    public static final byte PAULIX = (byte) 0x91;
    public static final byte PAULIY = (byte) 0x92;
    public static final byte PAULIZ = (byte) 0x93;
    public static final byte CNOT = (byte) 0x94;
    public static final byte TOFFOLI = (byte) 0x95;
    public static final byte MEASURE = (byte) 0x96;

  static {
    // Initialize handlers map
    // registerHandler(PUSH, new PushHandler());
    // registerHandler(POP, new PopHandler());
    // registerHandler(SWAP, new SwapHandler());
    // registerHandler(DUP, new DupHandler());

    // registerHandler(ADD, new AddHandler());
    // registerHandler(SUB, new SubHandler());
    // registerHandler(MUL, new MulHandler());
    // registerHandler(DIV, new DivHandler());
    registerHandler(INC, new IncrementHandler());
    // registerHandler(DEC, new DecrementHandler());

    // registerHandler(LOAD, new LoadHandler());
    // registerHandler(STORE, new StoreHandler());
    // registerHandler(ALLOC, new AllocHandler());
    // registerHandler(FREE, new FreeHandler());

    // registerHandler(JUMP, new JumpHandler());
    // registerHandler(BRANCH, new BranchHandler());
    // registerHandler(CALL, new CallHandler());
    // registerHandler(RETURN, new ReturnHandler());

    // Thread operations
    // registerHandler(THNEW, new ThreadNewHandler());
    // registerHandler(THJOIN, new ThreadJoinHandler());
    // registerHandler(THYIELD, new ThreadYieldHandler());
    // registerHandler(THEXIT, new ThreadExitHandler());

    // Synchronization
    // registerHandler(LOCK, new LockHandler());
    // registerHandler(UNLOCK, new UnlockHandler());
    // registerHandler(BARRIER, new BarrierHandler());
    // registerHandler(FENCE, new FenceHandler());

    // Channel operations
    // registerHandler(CHCREATE, new ChannelCreateHandler());
    // registerHandler(CHSEND, new ChannelSendHandler());
    // registerHandler(CHRECV, new ChannelReceiveHandler());
    // registerHandler(CHCLOSE, new ChannelCloseHandler());

    // Transaction operations
    // registerHandler(TXBEGIN, new TransactionBeginHandler());
    // registerHandler(TXCOMMIT, new TransactionCommitHandler());
    // registerHandler(TXABORT, new TransactionAbortHandler());
    // registerHandler(TXREAD, new TransactionReadHandler());
    // registerHandler(TXWRITE, new TransactionWriteHandler());

    // History operations
    // registerHandler(HSAVE, new HistorySaveHandler());
    // registerHandler(HRESTORE, new HistoryRestoreHandler());
    // registerHandler(HGC, new HistoryGCHandler());
    // registerHandler(HQUERY, new HistoryQueryHandler());
  }

  public static void registerHandler(byte opcode, InstructionHandler handler) {
    handlers.put(opcode, handler);
  }

  public static InstructionHandler getHandler(byte opcode) {
    InstructionHandler handler = handlers.get(opcode);
    if (handler == null) {
      throw new InvalidInstructionException("Unknown opcode", opcode, 0L);
    }
    return handler;
  }

  public static class Flags {
    public static final byte FORWARD = 0x00;
    public static final byte REVERSE = 0x01;
    public static final byte HISTORY = 0x02;
    public static final byte ATOMIC = 0x04;
    public static final byte INTERTHREAD = 0x08;
  }

  // Utility method to check if an instruction has a specific flag
  public static boolean hasFlag(byte flags, byte flag) {
    return (flags & flag) != 0;
  }

  // Instruction verification
  public static void verifyInstruction(byte opcode, byte flags, long operand) {
    InstructionHandler handler = getHandler(opcode);

    // Basic verification
    if ((flags & ~0x0F) != 0) { // Check for invalid flags
      throw new InvalidInstructionException("Invalid flags in instruction", opcode, 0L);
    }

    // Verify reversibility requirements
    if (requiresHistory(opcode) && !hasFlag(flags, Flags.HISTORY)) {
      throw new InvalidInstructionException("Instruction requires history tracking", opcode, 0L);
    }

    // Let the handler perform specific verification
    handler.verify(new Instruction(opcode, flags, (short)0, operand, 0));
  }

  // Check if an instruction requires history tracking
  private static boolean requiresHistory(byte opcode) {
    // Instructions that modify state must track history
    return opcode != SWAP && opcode != DUP && opcode != FENCE && opcode != HQUERY;
  }

  // Get instruction name for debugging
  public static String getInstructionName(byte opcode) {
    switch (opcode) {
      case PUSH:
        return "PUSH";
      case POP:
        return "POP";
      case SWAP:
        return "SWAP";
      case DUP:
        return "DUP";
      case ADD:
        return "ADD";
      case SUB:
        return "SUB";
      case MUL:
        return "MUL";
      case DIV:
        return "DIV";
      case INC:
        return "INC";
      case DEC:
        return "DEC";
      case LOAD:
        return "LOAD";
      case STORE:
        return "STORE";
      case ALLOC:
        return "ALLOC";
      case FREE:
        return "FREE";
      case JUMP:
        return "JUMP";
      case BRANCH:
        return "BRANCH";
      case CALL:
        return "CALL";
      case RETURN:
        return "RETURN";
      case THNEW:
        return "THNEW";
      case THJOIN:
        return "THJOIN";
      case THYIELD:
        return "THYIELD";
      case THEXIT:
        return "THEXIT";
      case LOCK:
        return "LOCK";
      case UNLOCK:
        return "UNLOCK";
      case BARRIER:
        return "BARRIER";
      case FENCE:
        return "FENCE";
      case CHCREATE:
        return "CHCREATE";
      case CHSEND:
        return "CHSEND";
      case CHRECV:
        return "CHRECV";
      case CHCLOSE:
        return "CHCLOSE";
      case TXBEGIN:
        return "TXBEGIN";
      case TXCOMMIT:
        return "TXCOMMIT";
      case TXABORT:
        return "TXABORT";
      case TXREAD:
        return "TXREAD";
      case TXWRITE:
        return "TXWRITE";
      case HSAVE:
        return "HSAVE";
      case HRESTORE:
        return "HRESTORE";
      case HGC:
        return "HGC";
      case HQUERY:
        return "HQUERY";

      default:
        return String.format("UNKNOWN(0x%02X)", opcode);
    }
  }
}
