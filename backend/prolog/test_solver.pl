/*  test_solver.pl: testes plunit de solver.pl.

    Rodar: make test-prolog
*/

% Um módulo próprio isola os predicados auxiliares deste arquivo dos
% outros arquivos de teste, que são carregados juntos.
:- module(test_solver, []).

:- use_module(solver).
:- use_module(regras).
:- use_module(library(plunit)).
:- use_module(library(apply)).
:- use_module(library(lists)).

%   Lights Out clássico 5x5 (só cruz) com apenas a luz do centro acesa.
%   Valores conhecidos: 4 soluções, a menor com 11 cliques.
centro_aceso(fase([[0,0,0,0,0],
                   [0,0,0,0,0],
                   [0,0,1,0,0],
                   [0,0,0,0,0],
                   [0,0,0,0,0]], Carimbos)) :-
    so_cruz(Carimbos).

%   Só o canto aceso, no clássico 5x5: não tem solução.
canto_aceso(fase([[1,0,0,0,0],
                  [0,0,0,0,0],
                  [0,0,0,0,0],
                  [0,0,0,0,0],
                  [0,0,0,0,0]], Carimbos)) :-
    so_cruz(Carimbos).

so_cruz(Carimbos) :-
    length(Fileira, 5), maplist(=(cruz), Fileira),
    length(Carimbos, 5), maplist(=(Fileira), Carimbos).

%   Uma fase com carimbos variados e travas, montada a partir do tabuleiro
%   apagado com 3 cliques. Assim ela com certeza tem solução.
fase_com_travas(Fase) :-
    Carimbos = [[cruz,   xis,    trava,  linha,  cruz],
                [bloco,  cruz,   coluna, xis,    cruz],
                [cruz,   trava,  cruz,   cruz,   linha],
                [linha,  xis,    cruz,   bloco,  trava],
                [cruz,   coluna, cruz,   cruz,   xis]],
    Apagada = [[0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]],
    foldl(apertar, [0-0, 2-2, 4-3], fase(Apagada, Carimbos), Fase).


:- begin_tests(num_solucoes).

test(centro_aceso, N == 4) :-
    centro_aceso(Fase),
    num_solucoes(Fase, N).

test(canto_aceso_nao_tem_solucao, N == 0) :-
    canto_aceso(Fase),
    num_solucoes(Fase, N).

:- end_tests(num_solucoes).


:- begin_tests(solucao_minima).

test(centro_aceso, Total == 11) :-
    centro_aceso(Fase),
    solucao_minima(Fase, _, Total).

test(sem_solucao, fail) :-
    canto_aceso(Fase),
    solucao_minima(Fase, _, _).

%   A prova de fogo: aplicar a solução com o apertar/3 de regras.pl, que não
%   sabe nada do modelo de restrições, precisa apagar tudo.
test(solucao_apaga_tudo) :-
    fase_com_travas(Fase),
    solucao_minima(Fase, Cliques, _),
    foldl(apertar, Cliques, Fase, Final),
    resolvida(Final).

test(nunca_clica_em_trava) :-
    fase_com_travas(Fase),
    Fase = fase(_, Carimbos),
    solucao_minima(Fase, Cliques, _),
    forall(member(Posicao, Cliques), \+ celula(Carimbos, Posicao, trava)).

:- end_tests(solucao_minima).


:- begin_tests(dica).

test(fase_resolvida, Resultado == resolvida) :-
    so_cruz(Carimbos),
    Apagada = [[0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]],
    dica(fase(Apagada, Carimbos), Resultado).

test(sem_solucao, Resultado == sem_solucao) :-
    canto_aceso(Fase),
    dica(Fase, Resultado).

%   Seguir a dica deixa a fase exatamente um clique mais perto do fim.
test(dica_reduz_o_minimo_em_um, Depois =:= Antes - 1) :-
    fase_com_travas(Fase),
    solucao_minima(Fase, _, Antes),
    dica(Fase, Posicao),
    apertar(Posicao, Fase, Seguinte),
    solucao_minima(Seguinte, _, Depois).

:- end_tests(dica).
