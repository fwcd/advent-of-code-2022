:- use_module(library(dcg/basics)).

% +---------+
% | Helpers |
% +---------+

% Concatenates a list of strings.
join([], "") :- !.
join([Str|Strs], Result) :- join(Strs, Rest), string_concat(Str, Rest, Result).

% +----------------------------------------------------------------+
% | Part 1: Assemble the equation list into a tree and evaluate it |
% +----------------------------------------------------------------+

% Looks up the expression for a variable in the given equation list.
lookup_expr(Var, [eqn(Var, Expr)|_], Expr) :- !.
lookup_expr(Var, [_|Eqns], Expr) :- lookup_expr(Var, Eqns, Expr).

% Assembles the given equation list to a tree with the given variable as root.
build_tree(Root, Eqns, named(Var, const(X))) :- lookup_expr(Root, Eqns, named(Var, const(X))), !.
build_tree(Root, Eqns, named(Var, bin_op(Lhs, Op, Rhs))) :-
  lookup_expr(Root, Eqns, named(Var, bin_op(LhsVar, Op, RhsVar))),
  build_tree(LhsVar, Eqns, Lhs),
  build_tree(RhsVar, Eqns, Rhs).

% Applies a binary operator.
eval(X, plus, Y, Z) :- Z is X + Y, !.
eval(X, minus, Y, Z) :- Z is X - Y, !.
eval(X, times, Y, Z) :- Z is X * Y, !.
eval(X, div, Y, Z) :- Z is X rdiv Y, !.

% Evaluates the given expression tree.
eval_tree(const(X), X) :- !.
eval_tree(named(_, Expr), X) :- eval_tree(Expr, X), !.
eval_tree(bin_op(Lhs, Op, Rhs), Z) :- eval_tree(Lhs, X), eval_tree(Rhs, Y), eval(X, Op, Y, Z), !.

% Strips name nodes from the given expression tree.
strip_tree(named(_, Expr), StrippedExpr) :- strip_tree(Expr, StrippedExpr), !.
strip_tree(const(X), const(X)) :- !.
strip_tree(bin_op(Lhs, Op, Rhs), bin_op(StrippedLhs, Op, StrippedRhs)) :- strip_tree(Lhs, StrippedLhs), strip_tree(Rhs, StrippedRhs).

% Converts the given operator to a prettyprinted string.
pretty_op(plus, "+").
pretty_op(minus, "-").
pretty_op(times, "*").
pretty_op(div, "/").

% Converts the given expression to a prettyprinted string.
pretty_tree(const(X), XStr) :- number_string(X, XStr), !.
pretty_tree(named(Var, Expr), Str) :-
  pretty_tree(Expr, ExprStr),
  atom_string(Var, VarStr),
  join([VarStr, "[", ExprStr, "]"], Str).
pretty_tree(bin_op(Lhs, Op, Rhs), Str) :-
  pretty_tree(Lhs, LhsStr),
  pretty_op(Op, OpStr),
  pretty_tree(Rhs, RhsStr),
  join(["(", LhsStr, ") ", OpStr, " (", RhsStr, ")"], Str).

% Converts the given equation to a prettyprinted string.
pretty_eqn(eqn(Lhs, Rhs), Str) :-
  pretty_tree(Lhs, LhsStr),
  pretty_tree(Rhs, RhsStr),
  join([LhsStr, " = ", RhsStr], Str).

% +----------------------------------------------------------+
% | Part 2: Transform the tree into an equation and solve it |
% +----------------------------------------------------------+

% Computes the inverse operator.
inverse(plus, minus).
inverse(minus, plus).
inverse(times, div).
inverse(div, times).

% Checks whether the operator is + or *.
positive_op(plus).
positive_op(times).

% Transforms the part 1-style expression tree to a part 2-style equation.
part1_tree_to_part2_eqn(named(root, bin_op(Lhs, _, Rhs)), eqn(Lhs, Rhs)).

% Solves the equation for Var, assuming Var is located in the left-hand side of the equation.
solve_in_lhs(Var, eqn(named(Var, _), Rhs), Rhs) :- !.
solve_in_lhs(Var, eqn(named(_, bin_op(OpLhs, Op, OpRhs)), Rhs), Solution) :-
  inverse(Op, InvOp),
  (
    (
      % Var is in OpLhs
      solve_in_lhs(Var, eqn(OpLhs, bin_op(Rhs, InvOp, OpRhs)), Solution),
      !
    ); 
    (
      % Var is in OpRhs and Op is + or *
      positive_op(Op),
      !,
      solve_in_lhs(Var, eqn(OpRhs, bin_op(Rhs, InvOp, OpLhs)), Solution)
    );
    (
      % Var is in OpRhs and Op is - or /
      solve_in_lhs(Var, eqn(OpRhs, bin_op(OpLhs, Op, Rhs)), Solution)
    )     
  ).

% Solves the equation for Var, regardless of which side of the equation Var is located in.
% Var is assumed to occur only once in the equation.
solve_for(Var, eqn(Lhs, Rhs), Solution) :-
  (solve_in_lhs(Var, eqn(Lhs, Rhs), Solution), !);
  (solve_in_lhs(Var, eqn(Rhs, Lhs), Solution)).

% +---------------------------+
% | DCG for parsing the input |
% +---------------------------+

dcg_eqns([])     --> eos, !.
dcg_eqns([E|Es]) --> dcg_eqn(E), dcg_eqns(Es).

dcg_eqn(eqn(Res, named(Res, Expr))) --> dcg_var(Res), ": ", dcg_expr(Expr), !.

dcg_expr(const(X)) --> number(X), eol, !.
dcg_expr(bin_op(LhsVar, Op, RhsVar)) --> dcg_var(LhsVar), " ", dcg_op(Op), " ", dcg_var(RhsVar), eol, !.

dcg_var(Id) --> string(IdCs),
  { atom_codes(Id, IdCs) }.

dcg_op(plus) --> "+", !.
dcg_op(minus) --> "-", !.
dcg_op(times) --> "*", !.
dcg_op(div) --> "/", !.

% +--------------+
% | Main program |
% +--------------+

parse_input(Eqns) :-
  phrase_from_file(dcg_eqns(Eqns), 'resources/input.txt').

println(X) :-
  print(X), nl.

main :-
  parse_input(Eqns),
  build_tree(root, Eqns, Tree),

  eval_tree(Tree, Part1),
  println(Part1),
  
  part1_tree_to_part2_eqn(Tree, Eqn),
  solve_for(humn, Eqn, SolutionTree),

  eval_tree(SolutionTree, Part2),
  println(Part2).
