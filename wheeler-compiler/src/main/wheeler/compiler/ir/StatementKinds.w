//! Defines canonical unresolved statement and form identities.

module wheeler.compiler.statement_kinds;

classical class StatementKinds {
  /// Direct assignment.
  public const long STATEMENT_ASSIGN = 0;
  /// A signed equality assertion.
  public const long STATEMENT_ASSERT_EQ = 768;
  /// A signed local declaration.
  public const long STATEMENT_LOCAL_LONG = 769;
  /// A Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN = 770;
  /// A negated Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT = 771;
  /// A Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN = 772;
  /// A negated Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN_NOT = 773;
  /// An assertion over a prior Boolean local.
  public const long STATEMENT_ASSERT_LOCAL_BOOLEAN = 774;
  /// Equality assertion over a signed name.
  public const long STATEMENT_ASSERT_NAMED_LONG = 775;
  /// Signed declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_LONG_NAMED = 776;
  /// Checked signed-local addition declaration.
  public const long STATEMENT_LOCAL_LONG_ADD_NAMED = 777;
  /// Checked signed-local subtraction declaration.
  public const long STATEMENT_LOCAL_LONG_SUB_NAMED = 778;
  /// Checked signed-local XOR declaration.
  public const long STATEMENT_LOCAL_LONG_XOR_NAMED = 779;
  /// Checked addition of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED = 780;
  /// Checked subtraction of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED = 781;
  /// Checked XOR of two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED = 782;
  /// Boolean declaration initialized from a prior local.
  public const long STATEMENT_LOCAL_BOOLEAN_NAMED = 783;
  /// Negated prior-Boolean declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT_NAMED = 784;
  /// Equality declaration over two prior locals.
  public const long STATEMENT_LOCAL_BOOLEAN_EQ_NAMED = 785;
  /// Less-than declaration over two prior signed locals.
  public const long STATEMENT_LOCAL_LONG_LT_NAMED = 786;
  /// One-arm local conditions guarding global updates.
  public const long STATEMENT_IF_LOCAL_ADD_NAMED = 787;
  /// One-arm local condition guarding subtraction.
  public const long STATEMENT_IF_LOCAL_SUB_NAMED = 788;
  /// One-arm local condition guarding XOR.
  public const long STATEMENT_IF_LOCAL_XOR_NAMED = 789;
  /// Multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_NAMED = 790;
  /// Division declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_DIV_NAMED = 791;
  /// Remainder declaration with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_MOD_NAMED = 792;
  /// Two-local multiplication, division, and remainder declarations.
  public const long STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED = 793;
  /// Division declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED = 794;
  /// Remainder declaration over two prior locals.
  public const long STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED = 795;
  /// Equality assertion over two prior locals.
  public const long STATEMENT_ASSERT_LOCAL_PAIR_NAMED = 796;
  /// Less-than assertion over prior signed locals.
  public const long STATEMENT_ASSERT_LONG_LT_NAMED = 797;
  /// Negated local condition guarding global addition.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_NAMED = 798;
  /// Negated local condition guarding global subtraction.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_NAMED = 799;
  /// Negated local condition guarding global XOR.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_NAMED = 800;
  /// Local condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_ASSIGN_NAMED = 801;
  /// Negated local condition guarding global assignment.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED = 802;
  /// Local condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED = 803;
  /// Negated condition assigning a prior signed local to global state.
  public const long STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED = 804;
  /// Global assignment from a prior signed local.
  public const long STATEMENT_ASSIGN_LOCAL_NAMED = 805;
  /// Checked global addition from a prior signed local.
  public const long STATEMENT_UPDATE_ADD_LOCAL_NAMED = 806;
  /// Checked global subtraction from a prior signed local.
  public const long STATEMENT_UPDATE_SUB_LOCAL_NAMED = 807;
  /// Global XOR from a prior signed local.
  public const long STATEMENT_UPDATE_XOR_LOCAL_NAMED = 808;
  /// Local condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_LOCAL_ADD_VALUE_NAMED = 809;
  /// Local condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_LOCAL_SUB_VALUE_NAMED = 810;
  /// Local condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_LOCAL_XOR_VALUE_NAMED = 811;
  /// Negated condition guarding addition from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED = 812;
  /// Negated condition guarding subtraction from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED = 813;
  /// Negated condition guarding XOR from a prior signed local.
  public const long STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED = 814;
  /// Signed-local equality with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED = 815;
  /// Signed-local less-than with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED = 816;
  /// Equality assertion over two signed literals.
  public const long STATEMENT_ASSERT_LITERAL_EQ = 817;
  /// Signed-local equality condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED = 818;
  /// Signed-local equality condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED = 819;
  /// Signed-local equality condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED = 820;
  /// Signed-local equality condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED = 821;
  /// Signed-local less-than condition guarding global addition.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED = 822;
  /// Signed-local less-than condition guarding global subtraction.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED = 823;
  /// Signed-local less-than condition guarding global XOR.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED = 824;
  /// Signed-local less-than condition guarding global assignment.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED = 825;
  /// Signed local initialized by a zero-argument helper call.
  public const long STATEMENT_LOCAL_CALL_NAMED = 826;
  /// Signed literal return from a helper.
  public const long STATEMENT_RETURN_LONG = 827;
  /// Signed return from a helper parameter.
  public const long STATEMENT_RETURN_LOCAL_NAMED = 828;
  /// Signed local initialized by a one-argument helper call.
  public const long STATEMENT_LOCAL_CALL_ARGUMENT_NAMED = 829;
  /// Signed helper return adding a literal to its parameter.
  public const long STATEMENT_RETURN_LOCAL_ADD_NAMED = 830;
  /// Signed helper return subtracting a literal from its parameter.
  public const long STATEMENT_RETURN_LOCAL_SUB_NAMED = 831;
  /// Signed helper return multiplying its parameter by a literal.
  public const long STATEMENT_RETURN_LOCAL_MUL_NAMED = 832;
  /// Signed helper return dividing its parameter by a literal.
  public const long STATEMENT_RETURN_LOCAL_DIV_NAMED = 833;
  /// Signed helper return taking its parameter modulo a literal.
  public const long STATEMENT_RETURN_LOCAL_MOD_NAMED = 834;
  /// Signed local initialized by passing a prior local to a helper.
  public const long STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED = 835;
  /// Signed helper return adding its parameter to itself.
  public const long STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED = 836;
  /// Signed helper return subtracting its parameter from itself.
  public const long STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED = 837;
  /// Signed helper return multiplying its parameter by itself.
  public const long STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED = 838;
  /// Signed helper return dividing its parameter by itself.
  public const long STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED = 839;
  /// Signed helper return reducing its parameter modulo itself.
  public const long STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED = 840;
  /// Signed local initialized by two literal helper arguments.
  public const long STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED = 841;
  /// Two-argument helper call with a prior local first.
  public const long STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED = 842;
  /// Two-argument helper call with a prior local second.
  public const long STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED = 843;
  /// Two-argument helper call with two prior locals.
  public const long STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED = 844;
  /// Boolean local initialized by a zero-argument helper call.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_NAMED = 845;
  /// Boolean literal return from a helper.
  public const long STATEMENT_RETURN_BOOLEAN = 846;
  /// Boolean result call with one literal argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED = 847;
  /// Boolean result call with one prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED = 848;
  /// Boolean result call with two literal arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED = 849;
  /// Boolean result call with a first prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED = 850;
  /// Boolean result call with a second prior-local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED = 851;
  /// Boolean result call with two prior-local arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED = 852;
  /// Signed helper return XORing its parameter with a literal.
  public const long STATEMENT_RETURN_LOCAL_XOR_NAMED = 853;
  /// Signed helper return XORing two parameters.
  public const long STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED = 854;
  /// Boolean helper return negating one parameter or prior local.
  public const long STATEMENT_RETURN_BOOLEAN_NOT_NAMED = 855;
  /// Boolean helper return comparing one local with a literal.
  public const long STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED = 856;
  /// Boolean helper return comparing two locals.
  public const long STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED = 857;
  /// Signed-local AND declaration.
  public const long STATEMENT_LOCAL_LONG_AND_NAMED = 858;
  /// AND declaration over two signed locals.
  public const long STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED = 859;
  /// Signed helper return ANDing one local with a literal.
  public const long STATEMENT_RETURN_LOCAL_AND_NAMED = 860;
  /// Signed helper return ANDing two locals.
  public const long STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED = 861;
  /// Inequality declaration over two prior locals.
  public const long STATEMENT_LOCAL_BOOLEAN_NE_NAMED = 862;
  /// Signed-local inequality with a literal right operand.
  public const long STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED = 863;
  /// Boolean helper inequality return with a literal right operand.
  public const long STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED = 864;
  /// Boolean helper inequality return over two locals.
  public const long STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED = 865;
  /// Boolean-result helper call with one signed literal argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED = 866;
  /// Boolean-result helper call with one prior signed local argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED = 867;
  /// Boolean-result helper call with two signed literal arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED = 868;
  /// Boolean-result helper call with a prior signed first argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED = 869;
  /// Boolean-result helper call with a prior signed second argument.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED = 870;
  /// Boolean-result helper call with two prior signed local arguments.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED = 871;
  /// Signed equality return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED = 872;
  /// Signed equality return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED = 873;
  /// Signed inequality return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED = 874;
  /// Signed inequality return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED = 875;
  /// Signed less-than return with a literal right operand.
  public const long STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED = 876;
  /// Signed less-than return with a local right operand.
  public const long STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED = 877;
  /// Bounded signed-local while loop before typed resolution.
  public const long STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED = 878;
  /// Resolved global equality assertion against a class constant.
  public const long STATEMENT_ASSERT_GLOBAL_CONSTANT = 879;
  /// Parameter equality guard returning true.
  public const long STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED = 880;
  /// Parameter equality guard returning false.
  public const long STATEMENT_IF_SIGNED_EQ_RETURN_FALSE_NAMED = 881;
  /// Scalar helper-call guard returning true.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED = 882;
  /// Scalar helper-call guard returning false.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED = 883;
  /// Parameter equality guard returning a signed literal.
  public const long STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED = 884;
  /// Scalar helper-call guard returning a signed literal.
  public const long STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED = 885;
  /// Marks while condition whose right operand names a prior local.
  public const long STATEMENT_LOCAL_WHILE_CONDITION_NAMED = 1;
  /// Marks while limit that names a prior local.
  public const long STATEMENT_LOCAL_WHILE_LIMIT_NAMED = 2;
  /// Checked subtraction for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_SUB_FORM = 4;
  /// Bitwise XOR for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_XOR_FORM = 8;
  /// Marks zero-to-local less-than condition.
  public const long STATEMENT_LOCAL_WHILE_REVERSED_FORM = 16;
  /// Bounds the closed while form column encoded beside one target local.
  public const long STATEMENT_LOCAL_WHILE_FORM_COUNT = 24;
  /// Checked global addition.
  public const long STATEMENT_UPDATE_ADD = 1040;
  /// Checked global subtraction.
  public const long STATEMENT_UPDATE_SUB = 1041;
  /// Global XOR.
  public const long STATEMENT_UPDATE_XOR = 1042;
}
