//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

import wheeler.lexer.scanner;

classical class Tokens {
  /// Caps compiler token metadata before comment compaction.
  public const long MAX_COMPILER_TOKENS = 1024;
  /// Reserves the unused final token cell for the resolved global name.
  public const long COMPILER_GLOBAL_NAME_TOKEN = MAX_COMPILER_TOKENS - 1;
  /// Distinguishes Boolean parameter markers from signed parameter markers.
  public const long BOOLEAN_PARAMETER_TOKEN_BIAS = MAX_COMPILER_TOKENS;

  /// Names the stable token hash for `module`.
  public const long TOKEN_MODULE = 3226183276;
  /// Names the stable token hash for `public`.
  public const long TOKEN_PUBLIC = 3317543529;
  /// Names the stable token hash for `private`.
  public const long TOKEN_PRIVATE = 102764717443;
  /// Names the stable token hash for `classical`.
  public const long TOKEN_CLASSICAL = 87497064671293;
  /// Names the stable token hash for `class`.
  public const long TOKEN_CLASS = 94742904;
  /// Names the stable token hash for `state`.
  public const long TOKEN_STATE = 109757585;
  /// Names the stable token hash for `entry`.
  public const long TOKEN_ENTRY = 96667762;
  /// Names the stable token hash for `void`.
  public const long TOKEN_VOID = 3625364;
  /// Names the stable token hash for `main`.
  public const long TOKEN_MAIN = 3343801;
  /// Names the stable token hash for `rev`.
  public const long TOKEN_REV = 112803;
  /// Names the stable token hash for `reverse`.
  public const long TOKEN_REVERSE = 104179061474;
  /// Names the stable token hash for `theorem`.
  public const long TOKEN_THEOREM = 106024553916;
  /// Names the stable token hash for `proves`.
  public const long TOKEN_PROVES = 3315169751;
  /// Names the stable token hash for `inverse`.
  public const long TOKEN_INVERSE = 96449190704;
  /// Names the stable token hash for `assert`.
  public const long TOKEN_ASSERT = 2886759238;
  /// Names the stable token hash for `if`.
  public const long TOKEN_IF = 3357;
  /// Names the stable token hash for `while`.
  public const long TOKEN_WHILE = 113101617;
  /// Names the stable token hash for `limit`.
  public const long TOKEN_LIMIT = 102976443;
  /// Names the stable token hash for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the stable token hash for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the stable token hash for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the stable token hash for `false`.
  public const long TOKEN_FALSE = 97196323;
  /// Names the stable token hash for `return`.
  public const long TOKEN_RETURN = 3360570672;

  /// Names the parser IR code for direct assignment.
  public const long STATEMENT_ASSIGN = 0;
  /// Names the parser IR code for a signed equality assertion.
  public const long STATEMENT_ASSERT_EQ = 768;
  /// Names the parser IR code for a signed local declaration.
  public const long STATEMENT_LOCAL_LONG = 769;
  /// Names the parser IR code for a Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN = 770;
  /// Names the parser IR code for a negated Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT = 771;
  /// Names the parser IR code for a Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN = 772;
  /// Names the parser IR code for a negated Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN_NOT = 773;
  /// Names the parser IR code for an assertion over a prior Boolean local.
  public const long STATEMENT_ASSERT_LOCAL_BOOLEAN = 774;
  /// Names an unresolved equality assertion over a signed name.
  public const long STATEMENT_ASSERT_NAMED_LONG = 775;
  /// Starts resolved signed-local assertion opcodes; the local index is the delta.
  public const long STATEMENT_ASSERT_LOCAL_LONG_BASE = 2048;
  /// Names an unresolved signed declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_LONG_NAMED = 776;
  /// Starts resolved signed-local copy opcodes; the source local is the delta.
  public const long STATEMENT_LOCAL_LONG_COPY_BASE = 2304;
  /// Names an unresolved checked signed-local addition declaration.
  public const long STATEMENT_LOCAL_LONG_ADD_NAMED = 777;
  /// Names an unresolved checked signed-local subtraction declaration.
  public const long STATEMENT_LOCAL_LONG_SUB_NAMED = 778;
  /// Names an unresolved checked signed-local XOR declaration.
  public const long STATEMENT_LOCAL_LONG_XOR_NAMED = 779;
  /// Starts resolved checked signed-local addition declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_ADD_BASE = 2560;
  /// Starts resolved checked signed-local subtraction declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_SUB_BASE = 2816;
  /// Starts resolved checked signed-local XOR declaration opcodes.
  public const long STATEMENT_LOCAL_LONG_XOR_BASE = 3072;
  /// Names an unresolved checked addition of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED = 780;
  /// Names an unresolved checked subtraction of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED = 781;
  /// Names an unresolved checked XOR of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED = 782;
  /// Starts resolved checked addition opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE = 3328;
  /// Starts resolved checked subtraction opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE = 3584;
  /// Starts resolved checked XOR opcodes for two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE = 3840;
  /// Names an unresolved Boolean declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_BOOLEAN_NAMED = 783;
  /// Starts resolved Boolean-local copy opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_COPY_BASE = 4096;
  /// Names an unresolved negated prior-Boolean declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_NAMED = 784;
  /// Starts resolved negated Boolean-local declaration opcodes.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_BASE = 4352;
  /// Names an unresolved equality declaration over two prior locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_NAMED = 785;
  /// Starts resolved equality declarations over prior Boolean locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_BASE = 4608;
  /// Starts resolved equality declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_EQ_BASE = 4864;
  /// Names an unresolved less-than declaration over two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_NAMED = 786;
  /// Starts resolved less-than declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_BASE = 5120;
  /// Names unresolved one-arm local conditions guarding global updates.
  public const long STATEMENT_IF_LOCAL_ADD_NAMED = 787;
  /// Names an unresolved one-arm local condition guarding subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_NAMED = 788;
  /// Names an unresolved one-arm local condition guarding XOR.
  public const long STATEMENT_IF_LOCAL_XOR_NAMED = 789;
  /// Starts resolved local conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_ADD_BASE = 5376;
  /// Starts resolved local conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_BASE = 5632;
  /// Starts resolved local conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_XOR_BASE = 5888;
  /// Names unresolved multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_NAMED = 790;
  /// Names an unresolved division declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_DIV_NAMED = 791;
  /// Names an unresolved remainder declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_MOD_NAMED = 792;
  /// Names unresolved two-local multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED = 793;
  /// Names an unresolved division declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED = 794;
  /// Names an unresolved remainder declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED = 795;
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
  /// Names an unresolved equality assertion over two prior locals.
  public const long STATEMENT_ASSERT_LOCAL_PAIR_NAMED = 796;
  /// Starts resolved equality assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_PAIR_BASE = 7680;
  /// Starts resolved equality assertions over prior Boolean locals.
  public const long STATEMENT_ASSERT_BOOLEAN_PAIR_BASE = 7936;
  /// Names an unresolved less-than assertion over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_NAMED = 797;
  /// Starts resolved less-than assertions over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_BASE = 8192;
  /// Names a negated local condition guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_NAMED = 798;
  /// Names a negated local condition guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_NAMED = 799;
  /// Names a negated local condition guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_NAMED = 800;
  /// Starts resolved negated local conditions guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_BASE = 8448;
  /// Starts resolved negated local conditions guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_BASE = 8704;
  /// Starts resolved negated local conditions guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_BASE = 8960;
  /// Names a local condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_NAMED = 801;
  /// Names a negated local condition guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED = 802;
  /// Starts resolved local conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_BASE = 9216;
  /// Starts resolved negated local conditions guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE = 9472;
  /// Names a local condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED = 803;
  /// Names a negated condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED = 804;
  /// Starts resolved local conditions assigning prior signed locals.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE = 9728;
  /// Starts resolved negated conditions assigning prior signed locals.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE = 9984;
  /// Names a global assignment from a prior signed local.
  public const long STATEMENT_ASSIGN_LOCAL_NAMED = 805;
  /// Names checked global addition from a prior signed local.
  public const long STATEMENT_UPDATE_ADD_LOCAL_NAMED = 806;
  /// Names checked global subtraction from a prior signed local.
  public const long STATEMENT_UPDATE_SUB_LOCAL_NAMED = 807;
  /// Names global XOR from a prior signed local.
  public const long STATEMENT_UPDATE_XOR_LOCAL_NAMED = 808;
  /// Names a local condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_LOCAL_ADD_VALUE_NAMED = 809;
  /// Names a local condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_LOCAL_SUB_VALUE_NAMED = 810;
  /// Names a local condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_LOCAL_XOR_VALUE_NAMED = 811;
  /// Names a negated condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED = 812;
  /// Names a negated condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED = 813;
  /// Names a negated condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED = 814;
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
  /// Names signed-local equality with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED = 815;
  /// Names signed-local less-than with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED = 816;
  /// Starts resolved signed-local equality with literal right operands.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE = 11776;
  /// Starts resolved signed-local less-than with literal right operands.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_BASE = 12032;
  /// Names an equality assertion over two signed literals.
  public const long STATEMENT_ASSERT_LITERAL_EQ = 817;
  /// Names a signed-local equality condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED = 818;
  /// Names a signed-local equality condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED = 819;
  /// Names a signed-local equality condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED = 820;
  /// Names a signed-local equality condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED = 821;
  /// Starts resolved equality conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE = 12288;
  /// Starts resolved equality conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE = 12544;
  /// Starts resolved equality conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE = 12800;
  /// Starts resolved equality conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE = 13056;
  /// Names a signed-local less-than condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED = 822;
  /// Names a signed-local less-than condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED = 823;
  /// Names a signed-local less-than condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED = 824;
  /// Names a signed-local less-than condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED = 825;
  /// Starts resolved less-than conditions guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE = 13312;
  /// Starts resolved less-than conditions guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE = 13568;
  /// Starts resolved less-than conditions guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE = 13824;
  /// Starts resolved less-than conditions guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE = 14080;
  /// Names a signed local initialized by a zero-argument helper call.
  public const long STATEMENT_LOCAL_CALL_NAMED = 826;
  /// Names a signed literal return from a helper.
  public const long STATEMENT_RETURN_LONG = 827;
  /// Names a signed return from a helper parameter.
  public const long STATEMENT_RETURN_LOCAL_NAMED = 828;
  /// Names a signed local initialized by a one-argument helper call.
  public const long STATEMENT_LOCAL_CALL_ARGUMENT_NAMED = 829;
  /// Names a signed helper return adding a literal to its parameter.
  public const long STATEMENT_RETURN_LOCAL_ADD_NAMED = 830;
  /// Names a signed helper return subtracting a literal from its parameter.
  public const long STATEMENT_RETURN_LOCAL_SUB_NAMED = 831;
  /// Names a signed helper return multiplying its parameter by a literal.
  public const long STATEMENT_RETURN_LOCAL_MUL_NAMED = 832;
  /// Names a signed helper return dividing its parameter by a literal.
  public const long STATEMENT_RETURN_LOCAL_DIV_NAMED = 833;
  /// Names a signed helper return taking its parameter modulo a literal.
  public const long STATEMENT_RETURN_LOCAL_MOD_NAMED = 834;
  /// Names a signed local initialized by passing a prior local to a helper.
  public const long STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED = 835;
  /// Names a signed helper return adding its parameter to itself.
  public const long STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED = 836;
  /// Names a signed helper return subtracting its parameter from itself.
  public const long STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED = 837;
  /// Names a signed helper return multiplying its parameter by itself.
  public const long STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED = 838;
  /// Names a signed helper return dividing its parameter by itself.
  public const long STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED = 839;
  /// Names a signed helper return reducing its parameter modulo itself.
  public const long STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED = 840;
  /// Names a signed local initialized by two literal helper arguments.
  public const long STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED = 841;
  /// Names a two-argument helper call with a prior local first.
  public const long STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED = 842;
  /// Names a two-argument helper call with a prior local second.
  public const long STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED = 843;
  /// Names a two-argument helper call with two prior locals.
  public const long STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED = 844;
  /// Names a Boolean local initialized by a zero-argument helper call.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_NAMED = 845;
  /// Names a Boolean literal return from a helper.
  public const long STATEMENT_RETURN_BOOLEAN = 846;
  /// Names a Boolean result call with one literal argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED = 847;
  /// Names a Boolean result call with one prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED = 848;
  /// Names a Boolean result call with two literal arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED = 849;
  /// Names a Boolean result call with a first prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED = 850;
  /// Names a Boolean result call with a second prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED = 851;
  /// Names a Boolean result call with two prior-local arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED = 852;
  /// Names a signed helper return XORing its parameter with a literal.
  public const long STATEMENT_RETURN_LOCAL_XOR_NAMED = 853;
  /// Names a signed helper return XORing two parameters.
  public const long STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED = 854;
  /// Names a Boolean helper return negating one parameter or prior local.
  public const long STATEMENT_RETURN_BOOLEAN_NOT_NAMED = 855;
  /// Names a Boolean helper return comparing one local with a literal.
  public const long STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED = 856;
  /// Names a Boolean helper return comparing two locals.
  public const long STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED = 857;
  /// Names an unresolved signed-local AND declaration.
  public const long STATEMENT_LOCAL_LONG_AND_NAMED = 858;
  /// Names an unresolved AND declaration over two signed locals.
  public const long STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED = 859;
  /// Names a signed helper return ANDing one local with a literal.
  public const long STATEMENT_RETURN_LOCAL_AND_NAMED = 860;
  /// Names a signed helper return ANDing two locals.
  public const long STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED = 861;
  /// Starts resolved signed-local AND declarations with literal right operands.
  public const long STATEMENT_LOCAL_LONG_AND_BASE = 14848;
  /// Starts resolved signed-local AND declarations over two prior locals.
  public const long STATEMENT_LOCAL_LONG_AND_LOCALS_BASE = 15104;
  /// Names an unresolved inequality declaration over two prior locals.
  public const long STATEMENT_LOCAL_BOOLEAN_NE_NAMED = 862;
  /// Names an unresolved signed-local inequality with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED = 863;
  /// Names a Boolean helper inequality return with a literal right operand.
  public const long STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED = 864;
  /// Names a Boolean helper inequality return over two locals.
  public const long STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED = 865;
  /// Starts resolved inequality declarations over prior Boolean locals.
  public const long STATEMENT_LOCAL_BOOLEAN_NE_BASE = 15360;
  /// Starts resolved inequality declarations over prior signed locals.
  public const long STATEMENT_LOCAL_LONG_NE_BASE = 15616;
  /// Starts resolved signed-local inequalities with literal right operands.
  public const long STATEMENT_LOCAL_LONG_NE_LITERAL_BASE = 15872;
  /// Names a Boolean-result helper call with one signed literal argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED = 866;
  /// Names a Boolean-result helper call with one prior signed local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED = 867;
  /// Names a Boolean-result helper call with two signed literal arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED = 868;
  /// Names a Boolean-result helper call with a prior signed first argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED = 869;
  /// Names a Boolean-result helper call with a prior signed second argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED = 870;
  /// Names a Boolean-result helper call with two prior signed local arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED = 871;
  /// Names a signed equality return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED = 872;
  /// Names a signed equality return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED = 873;
  /// Names a signed inequality return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED = 874;
  /// Names a signed inequality return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED = 875;
  /// Names a signed less-than return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED = 876;
  /// Names a signed less-than return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED = 877;
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
  /// Names one bounded signed-local while loop before typed resolution.
  public const long STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED = 878;
  /// Starts resolved bounded signed-local while loops.
  public const long STATEMENT_LOCAL_WHILE_BASE = 18688;
  /// Marks a while condition whose right operand names a prior local.
  public const long STATEMENT_LOCAL_WHILE_CONDITION_NAMED = 1;
  /// Marks a while limit that names a prior local.
  public const long STATEMENT_LOCAL_WHILE_LIMIT_NAMED = 2;
  /// Selects checked subtraction for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_SUB_FORM = 4;
  /// Selects bitwise XOR for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_XOR_FORM = 8;
  /// Marks a zero-to-local less-than condition.
  public const long STATEMENT_LOCAL_WHILE_REVERSED_FORM = 16;
  /// Bounds the closed while form column encoded beside one target local.
  public const long STATEMENT_LOCAL_WHILE_FORM_COUNT = 24;
  /// Starts resolved signed-local less-than assertions against literals.
  public const long STATEMENT_ASSERT_LONG_LT_LITERAL_BASE = 24832;
  /// Names the parser IR code for checked global addition.
  public const long STATEMENT_UPDATE_ADD = 1040;
  /// Names the parser IR code for checked global subtraction.
  public const long STATEMENT_UPDATE_SUB = 1041;
  /// Names the parser IR code for global XOR.
  public const long STATEMENT_UPDATE_XOR = 1042;

  /// Names the ASCII scalar for the canonical digit `0`.
  public const long SCALAR_DIGIT_ZERO = 48;
  /// Names the ASCII scalar for the canonical digit `1`.
  public const long SCALAR_DIGIT_ONE = 49;
  /// Names the ASCII scalar for the canonical digit `9`.
  public const long SCALAR_DIGIT_NINE = 57;
  /// Names the ASCII `!` punctuation scalar.
  public const long PUNCTUATION_BANG = 33;
  /// Names the ASCII `%` punctuation scalar.
  public const long PUNCTUATION_PERCENT = 37;
  /// Names the ASCII `&` punctuation scalar.
  public const long PUNCTUATION_AMPERSAND = 38;
  /// Names the ASCII `(` punctuation scalar.
  public const long PUNCTUATION_OPEN_PAREN = 40;
  /// Names the ASCII `)` punctuation scalar.
  public const long PUNCTUATION_CLOSE_PAREN = 41;
  /// Names the ASCII `*` punctuation scalar.
  public const long PUNCTUATION_STAR = 42;
  /// Names the ASCII `+` punctuation scalar.
  public const long PUNCTUATION_PLUS = 43;
  /// Names the ASCII `,` punctuation scalar.
  public const long PUNCTUATION_COMMA = 44;
  /// Names the ASCII `.` punctuation scalar.
  public const long PUNCTUATION_DOT = 46;
  /// Names the ASCII `-` punctuation scalar.
  public const long PUNCTUATION_MINUS = 45;
  /// Names the ASCII `/` punctuation scalar.
  public const long PUNCTUATION_SLASH = 47;
  /// Names the ASCII `;` punctuation scalar.
  public const long PUNCTUATION_SEMICOLON = 59;
  /// Names the ASCII `<` punctuation scalar.
  public const long PUNCTUATION_LESS_THAN = 60;
  /// Names the ASCII `=` punctuation scalar.
  public const long PUNCTUATION_ASSIGN = 61;
  /// Names the ASCII `^` punctuation scalar.
  public const long PUNCTUATION_CARET = 94;
  /// Names the ASCII `{` punctuation scalar.
  public const long PUNCTUATION_OPEN_BRACE = 123;
  /// Names the ASCII `}` punctuation scalar.
  public const long PUNCTUATION_CLOSE_BRACE = 125;

  /// Computes the stable hash of one bounded source token.
  public long tokenHash(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long cursor = tokenStarts[token];
    long end = cursor + tokenLengths[token];
    long hash = 0;
    while (cursor < end) limit 16 {
      hash = hash * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
  }

  /// Checks one token against an exact punctuation scalar.
  public boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    if (tokenKinds[token] == 3) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  /// Checks whether `tokenText` denotes the same canonical value.
  public boolean sameTokenText(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long left,
    long right
  ) {
    if (tokenLengths[left] == tokenLengths[right]) {
      long cursor = 0;
      while (cursor < tokenLengths[left]) limit 256 {
        long leftScalar = utf8Scalar(source, tokenStarts[left] + cursor);
        long rightScalar = utf8Scalar(source, tokenStarts[right] + cursor);
        if (leftScalar < rightScalar) {
          return false;
        }

        if (rightScalar < leftScalar) {
          return false;
        }

        cursor += 1;
      }

      return true;
    }

    return false;
  }

  /// Returns the token width consumed by one signed integer literal.
  public long signedNumberWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token
  ) {
    if (tokenKinds[token] == 2) {
      return 1;
    }

    if (punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_MINUS)) {
      if (tokenKinds[token + 1] == 2) {
        return 2;
      }
    }

    return -1;
  }

  /// Checks one signed integer token for canonical syntax.
  public boolean signedNumberValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    if (magnitude < 0) {
      return false;
    }

    return true;
  }

  /// Decodes one signed integer token after canonical syntax validation.
  public long parsedSignedNumber(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    long sign = 1;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
      sign = -1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    return sign * magnitude;
  }
}
