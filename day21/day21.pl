:- use_module(library(dcg/basics)).

% Equation and expression handling

lookup_expr(Var, [eqn(Var, Expr)|_], Expr) :- !.
lookup_expr(Var, [_|Eqns], Expr) :- lookup_expr(Var, Eqns, Expr).

build_tree(Root, Eqns, const(X)) :- lookup_expr(Root, Eqns, const(X)), !.
build_tree(Root, Eqns, bin_op(LhsNode, Op, RhsNode)) :-
  lookup_expr(Root, Eqns, bin_op(Lhs, Op, Rhs)),
  build_tree(Lhs, Eqns, LhsNode),
  build_tree(Rhs, Eqns, RhsNode).

% DCG for parsing the input

dcg_eqns([])     --> eos, !.
dcg_eqns([E|Es]) --> dcg_eqn(E), dcg_eqns(Es).

dcg_eqn(eqn(Res, Expr)) --> dcg_var(Res), ": ", dcg_expr(Expr), !.

dcg_expr(const(X)) --> number(X), eol, !.
dcg_expr(bin_op(Lhs, Op, Rhs)) --> dcg_var(Lhs), " ", dcg_op(Op), " ", dcg_var(Rhs), eol, !.

dcg_var(Id) --> string(IdCs),
  { atom_codes(Id, IdCs) }.

dcg_op(plus) --> "+", !.
dcg_op(minus) --> "-", !.
dcg_op(times) --> "*", !.
dcg_op(div) --> "/", !.

% Main program

parse_input(Eqns) :-
  phrase_from_file(dcg_eqns(Eqns), 'resources/demo.txt').

println(X) :-
  print(X), nl.

main :-
  parse_input(Eqns),
  build_tree(root, Eqns, Tree),

  println(Tree).
