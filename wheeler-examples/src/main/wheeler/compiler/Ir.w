module examples.compiler.ir;
classical class CompilerIr {
    public record SourceRange(long start, long length) {}

    public record MinimalProgram(
        SourceRange name,
        SourceRange global,
        long globalCount,
        long initialValue,
        long statementCount,
        long opcode,
        long operand,
        long secondOpcode,
        long secondOperand,
        long thirdOpcode,
        long thirdOperand,
        long fourthOpcode,
        long fourthOperand
    ) {}

    public variant MinimalProgramResult {
        case Value(MinimalProgram program);
        case Error(long offset);
    }
}
