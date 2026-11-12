/* Protótipo de VALIDAÇÃO da regra "carimbos + células travadas".
   Não é o código final do projeto.

   Fase = fase(Luzes, Carimbos, Travas), todas matrizes NxN:
     Luzes:    0/1  (1 = acesa)
     Carimbos: átomos (cruz, xis, linha, coluna, bloco)
     Travas:   0/1  (1 = travada: não pode ser clicada, mas é afetada)
*/
:- use_module(library(clpb)).
:- use_module(library(random)).
:- use_module(library(apply)).
:- use_module(library(lists)).

% ---- Carimbos: deslocamentos relativos afetados (sempre inclui a própria célula)
offsets(cruz,   [0-0, -1-0, 1-0, 0-(-1), 0-1]).
offsets(xis,    [0-0, -1-(-1), -1-1, 1-(-1), 1-1]).
offsets(linha,  [0-0, 0-(-1), 0-1, 0-(-2), 0-2]).
offsets(coluna, [0-0, -1-0, 1-0, -2-0, 2-0]).
offsets(bloco,  [-1-(-1), -1-0, -1-1, 0-(-1), 0-0, 0-1, 1-(-1), 1-0, 1-1]).

% afeta(+N, +Carimbos, ?Clicada, ?Afetada): clicar Clicada inverte Afetada
afeta(N, Carimbos, I-J, I2-J2) :-
    N1 is N-1, between(0, N1, I), between(0, N1, J),
    em(Carimbos, I-J, K), offsets(K, Offs), member(DI-DJ, Offs),
    I2 is I+DI, J2 is J+DJ, I2 >= 0, I2 < N, J2 >= 0, J2 < N.

em(M, I-J, V) :- nth0(I, M, L), nth0(J, L, V).

% ---- Modelo de restrições
% modelo(+Fase, -P, -Vars): P = matriz de apertos; Vars = as que estão livres
modelo(fase(Luzes, Carimbos, Travas), P, Livres) :-
    length(Luzes, N), length(P, N), maplist(tam(N), P),
    maplist(maplist(trava), Travas, P),          % travada => aperto = 0
    N1 is N-1,
    forall_cel(N1, Cells),
    maplist(restricao(N, Luzes, Carimbos, P), Cells),
    append(P, Vars), include(var, Vars, Livres).

tam(N, L) :- length(L, N).
trava(1, 0) :- !.
trava(0, _).
forall_cel(N1, Cells) :- findall(I-J, (between(0,N1,I), between(0,N1,J)), Cells).

restricao(N, Luzes, Carimbos, P, Alvo) :-
    em(Luzes, Alvo, Luz),
    findall(C, afeta(N, Carimbos, C, Alvo), Quem),
    maplist(em(P), Quem, Vs),
    foldl(xor, Vs, Luz, Expr),
    sat(Expr =:= 0).

xor(V, A, A # V).

% ---- Features
tem_solucao(F) :- \+ \+ modelo(F, _, _).

num_solucoes(F, C) :- ( modelo(F, _, L) -> sat_count(+[1|L], C) ; C = 0 ).

solucao_minima(F, P, K) :-
    aggregate_all(min(K0, P0),
                  ( modelo(F, P0, L), labeling(L), append(P0, Vs), sum_list(Vs, K0) ),
                  min(K, P)).

dica(F, Cel) :- solucao_minima(F, P, _), em(P, Cel, 1), !.

% ---- Simulador INDEPENDENTE do modelo (só aplica cliques), usado p/ validar
apertar(fase(L, C, T), Cel, fase(L2, C, T)) :-
    em(T, Cel, 0),                                 % não pode clicar travada
    length(L, N),
    findall(A, afeta(N, C, Cel, A), Afet),
    findall(Row, ( nth0(I, L, R),
                   findall(X2, ( nth0(J, R, X),
                                 ( memberchk(I-J, Afet) -> X2 is 1-X ; X2 = X ) ), Row) ),
            L2).

aplicar_solucao(F, P, F2) :-
    findall(I-J, (nth0(I, P, R), nth0(J, R, 1)), Cl),
    foldl(apertar_, Cl, F, F2).
apertar_(C, A, B) :- apertar(A, C, B).

apagado(fase(L,_,_)) :- append(L, Xs), \+ memberchk(1, Xs).

% ---- Gerador
% gerar(+N, +Kinds, +PctTrava, +Dif, -Fase)
gerar(N, Kinds, PctTrava, Dif, Fase) :-
    N1 is N-1, forall_cel(N1, Cells),
    repeat,
      matriz(N, random_member_(Kinds), Carimbos),
      matriz(N, sorteia_trava(PctTrava), Travas),
      matriz(N, =(0), Zero),
      F0 = fase(Zero, Carimbos, Travas),
      include(livre(Travas), Cells, Clicaveis),
      length(Clicaveis, NC), NC >= Dif,
      random_permutation(Clicaveis, Emb), length(Cl, Dif), append(Cl, _, Emb),
      foldl(apertar_, Cl, F0, Fase),
      solucao_minima(Fase, _, Min), Min =:= Dif, !.

random_member_(Kinds, X) :- random_member(X, Kinds).
sorteia_trava(Pct, X) :- R is random_float, ( R < Pct -> X = 1 ; X = 0 ).
matriz(N, G, M) :- length(M, N), maplist(linha_(N, G), M).
linha_(N, G, L) :- length(L, N), maplist(G, L).
livre(T, C) :- em(T, C, 0).
