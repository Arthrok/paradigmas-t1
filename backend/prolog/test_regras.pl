/*  test_regras.pl: testes plunit de regras.pl.

    Rodar: make test-prolog
*/

% Um módulo próprio isola os predicados auxiliares deste arquivo dos
% outros arquivos de teste, que são carregados juntos.
:- module(test_regras, []).

:- use_module(regras).
:- use_module(library(plunit)).
:- use_module(library(apply)).
:- use_module(library(lists)).

%   matriz(+N, +Valor, -Matriz): matriz NxN com Valor em todas as células.
matriz(N, Valor, Matriz) :-
    length(Fileira, N),
    maplist(=(Valor), Fileira),
    length(Matriz, N),
    maplist(=(Fileira), Matriz).

%   afetadas(+Carimbos, +Clicada, -Afetadas): todas, em ordem.
afetadas(Carimbos, Clicada, Afetadas) :-
    findall(A, afeta(Carimbos, Clicada, A), Lista),
    msort(Lista, Afetadas).


:- begin_tests(carimbos).

test(cruz_no_centro, Afetadas == [1-2, 2-1, 2-2, 2-3, 3-2]) :-
    matriz(5, cruz, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas).

test(xis_no_centro, Afetadas == [1-1, 1-3, 2-2, 3-1, 3-3]) :-
    matriz(5, xis, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas).

test(linha_no_centro, Afetadas == [2-0, 2-1, 2-2, 2-3, 2-4]) :-
    matriz(5, linha, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas).

test(coluna_no_centro, Afetadas == [0-2, 1-2, 2-2, 3-2, 4-2]) :-
    matriz(5, coluna, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas).

test(bloco_no_centro, Total == 9) :-
    matriz(5, bloco, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas),
    length(Afetadas, Total).

test(trava_nao_afeta_nada, Afetadas == []) :-
    matriz(5, trava, Carimbos),
    afetadas(Carimbos, 2-2, Afetadas).

test(borda_corta_o_carimbo, Afetadas == [0-0, 0-1, 1-0]) :-
    matriz(5, cruz, Carimbos),
    afetadas(Carimbos, 0-0, Afetadas).

test(linha_na_borda, Afetadas == [2-0, 2-1, 2-2]) :-
    matriz(5, linha, Carimbos),
    afetadas(Carimbos, 2-0, Afetadas).

:- end_tests(carimbos).


:- begin_tests(afeta_como_relacao).

%   O mesmo predicado responde "quem me inverte?".
test(quem_inverte_o_canto, Quem == [0-0, 0-1, 1-0]) :-
    matriz(5, cruz, Carimbos),
    findall(Q, afeta(Carimbos, Q, 0-0), Lista),
    msort(Lista, Quem).

:- end_tests(afeta_como_relacao).


:- begin_tests(apertar).

test(inverte_as_celulas_do_carimbo, Luzes == [[1,1,0,0],
                                               [1,0,0,0],
                                               [0,0,0,0],
                                               [0,0,0,0]]) :-
    matriz(4, 0, Apagadas),
    matriz(4, cruz, Carimbos),
    apertar(0-0, fase(Apagadas, Carimbos), fase(Luzes, _)).

test(apertar_duas_vezes_desfaz, Depois == Antes) :-
    Antes = fase([[1,0,1,0], [0,1,1,0], [0,0,0,1], [1,1,0,0]],
                 [[cruz,xis,linha,coluna], [bloco,cruz,xis,linha],
                  [coluna,bloco,cruz,xis], [linha,coluna,bloco,cruz]]),
    apertar(1-2, Antes, Meio),
    apertar(1-2, Meio, Depois).

test(trava_nao_pode_ser_clicada, fail) :-
    matriz(4, 0, Luzes),
    matriz(4, trava, Carimbos),
    apertar(1-1, fase(Luzes, Carimbos), _).

:- end_tests(apertar).


:- begin_tests(resolvida).

test(tudo_apagado) :-
    matriz(4, 0, Luzes),
    matriz(4, cruz, Carimbos),
    resolvida(fase(Luzes, Carimbos)).

test(uma_luz_acesa, fail) :-
    matriz(4, cruz, Carimbos),
    resolvida(fase([[0,0,0,0], [0,0,0,0], [0,0,1,0], [0,0,0,0]], Carimbos)).

:- end_tests(resolvida).
