//! Defines canonical resolved statement opcode columns.

module wheeler.compiler.resolved_statements;

classical class ResolvedStatements {
  /// Starts resolved signed-local assertion opcodes; the local index is the delta.
  public const long STATEMENT_ASSERT_LOCAL_LONG_BASE = 2048;
  /// Starts resolved signed-local copy opcodes; the source local is the delta.
  public const long STATEMENT_LOCAL_LONG_COPY_BASE = 2304;
  /// Starts resolved checked signed-local addition declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_ADD_BASE = 2560;
  /// Starts resolved checked signed-local subtraction declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_SUB_BASE = 2816;
  /// Starts resolved checked signed-local XOR declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_XOR_BASE = 3072;
  /// Starts resolved checked addition opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE = 3328;
  /// Starts resolved checked subtraction opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE = 3584;
  /// Starts resolved checked XOR opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE = 3840;
  /// Starts resolved Boolean-local copy opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_COPY_BASE = 4096;
  /// Starts resolved negated Boolean-local declaration opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_BASE = 4352;
  /// Starts resolved equality declarations over prior Boolean locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_BASE = 4608;
  /// Starts resolved equality declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_EQ_BASE = 4864;
  /// Starts resolved less-than declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_BASE = 5120;
  /// Starts resolved local conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_ADD_BASE = 5376;
  /// Starts resolved local conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_BASE = 5632;
  /// Starts resolved local conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_XOR_BASE = 5888;
  /// Starts resolved multiplication declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_MUL_BASE = 6144;
  /// Starts resolved division declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_DIV_BASE = 6400;
  /// Starts resolved remainder declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_MOD_BASE = 6656;
  /// Starts resolved multiplication declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE = 6912;
  /// Starts resolved division declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE = 7168;
  /// Starts resolved remainder declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE = 7424;
  /// Starts resolved equality assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_PAIR_BASE = 7680;
  /// Starts resolved equality assertions over prior Boolean locals.
  public const long STATEMENT_ASSERT_BOOLEAN_PAIR_BASE = 7936;
  /// Starts resolved less-than assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_BASE = 8192;
  /// Starts resolved negated local conditions guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_BASE = 8448;
  /// Starts resolved negated local conditions guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_BASE = 8704;
  /// Starts resolved negated local conditions guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_BASE = 8960;
  /// Starts resolved local conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_BASE = 9216;
  /// Starts resolved negated local conditions guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE = 9472;
  /// Starts resolved local conditions assigning prior signed locals.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE = 9728;
  /// Starts resolved negated conditions assigning prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE = 9984;
  /// Starts local conditions guarding addition from prior signed locals.
  public const long STATEMENT_IF_LOCAL_ADD_VALUE_BASE = 10240;
  /// Starts local conditions guarding subtraction from prior signed locals.
  public const long STATEMENT_IF_LOCAL_SUB_VALUE_BASE = 10496;
  /// Starts local conditions guarding XOR from prior signed locals.
  public const long STATEMENT_IF_LOCAL_XOR_VALUE_BASE = 10752;
  /// Starts negated conditions guarding addition from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE = 11008;
  /// Starts negated conditions guarding subtraction from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE = 11264;
  /// Starts negated conditions guarding XOR from prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE = 11520;
  /// Starts resolved signed-local equality with literal right operands.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE = 11776;
  /// Starts resolved signed-local less-than with literal right operands.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_BASE = 12032;
  /// Starts resolved equality conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE = 12288;
  /// Starts resolved equality conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE = 12544;
  /// Starts resolved equality conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE = 12800;
  /// Starts resolved equality conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE = 13056;
  /// Starts resolved less-than conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE = 13312;
  /// Starts resolved less-than conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE = 13568;
  /// Starts resolved less-than conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE = 13824;
  /// Starts resolved less-than conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE = 14080;
  /// Starts resolved signed-local AND declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_AND_BASE = 14848;
  /// Starts resolved signed-local AND declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_AND_LOCALS_BASE = 15104;
  /// Starts resolved inequality declarations over prior Boolean locals.
  public const long STATEMENT_LOCAL_BOOLEAN_NE_BASE = 15360;
  /// Starts resolved inequality declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_NE_BASE = 15616;
  /// Starts resolved signed-local inequalities with literal right operands.
  public const long STATEMENT_LOCAL_LONG_NE_LITERAL_BASE = 15872;
  /// Starts resolved local additions with literal right operands.
  public const long STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE = 16128;
  /// Starts resolved local additions with prior-local right operands.
  public const long STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE = 16384;
  /// Starts resolved local subtractions with literal right operands.
  public const long STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE = 16640;
  /// Starts resolved local subtractions with prior-local right operands.
  public const long STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE = 16896;
  /// Starts resolved local XOR updates with literal right operands.
  public const long STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE = 17152;
  /// Starts resolved local XOR updates with prior-local right operands.
  public const long STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE = 17408;
  /// Starts resolved signed-local assignments from literals.
  public const long STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE = 17664;
  /// Starts resolved signed-local assignments from prior locals.
  public const long STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE = 17920;
  /// Starts resolved Boolean-local assignments from literals.
  public const long STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE = 18176;
  /// Starts resolved Boolean-local assignments from prior locals.
  public const long STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE = 18432;
  /// Starts resolved parameter equality guards returning a Boolean.
  public const long STATEMENT_IF_SIGNED_EQ_RETURN_BASE = 25856;
  /// Starts resolved scalar helper-call guards returning a Boolean.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_BASE = 26112;
  /// Starts resolved parameter equality guards returning a signed literal.
  public const long STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE = 26368;
  /// Starts resolved helper-call guards returning a signed literal.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE = 26624;
  /// Starts resolved parameter less-than guards returning a Boolean.
  public const long STATEMENT_IF_SIGNED_LT_RETURN_BASE = 26880;
  /// Starts resolved parameter less-than guards returning a signed literal.
  public const long STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE = 27136;
  /// Starts resolved parameter less-than guards returning checked subtraction.
  public const long STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE = 27392;
  /// Starts resolved scalar helper returns forwarding a one-argument call result.
  public const long STATEMENT_RETURN_HELPER_CALL_BASE = 27648;
  /// Names a resolved scalar helper return forwarding a zero-argument call result.
  public const long STATEMENT_RETURN_HELPER_CALL_ZERO = 27904;
  /// Starts resolved parameter less-than guards returning checked remainder.
  public const long STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE = 28160;
  /// Starts resolved helper-call guards forwarding another one-argument Boolean call.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_BASE = 28416;
  /// Starts resolved scalar helper returns forwarding a two-argument call result.
  public const long STATEMENT_RETURN_HELPER_CALL_TWO_BASE = 65536;
  /// Starts resolved bounded signed-local while loops.
  public const long STATEMENT_LOCAL_WHILE_BASE = 18688;
  /// Starts resolved signed-local less-than assertions against literals.
  public const long STATEMENT_ASSERT_LONG_LT_LITERAL_BASE = 24832;
  /// Starts resolved Boolean-local equality declarations against literals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_LITERAL_BASE = 25088;
  /// Starts resolved Boolean-local inequality declarations against literals.
  public const long STATEMENT_LOCAL_BOOLEAN_NE_LITERAL_BASE = 25344;
  /// Starts resolved Boolean-local equality assertions against literals.
  public const long STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE = 25600;
}
