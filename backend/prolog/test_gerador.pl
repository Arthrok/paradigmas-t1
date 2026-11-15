/*  test_gerador.pl: testes plunit de gerador.pl.

    Rodar: make test-prolog

    O gerador sorteia; set_random(seed(...)) fixa a semente para que os
    testes sejam reprodutíveis.
*/

% Um módulo próprio isola os predicados auxiliares deste arquivo dos
% outros arquivos de teste, que são carregados juntos.
:- module(test_gerador, []).

:- use_module(gerador).
:- use_module(solver).
:- use_module(regras).
:- use_module(library(plunit)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).

:- begin_tests(gerar).

test(dificuldade_exata, Minimo == 6) :-
    set_random(seed(42)),
    gerar(carimbos_travas, 5, 6, Fase),
    solucao_minima(Fase, _, Minimo).

test(fase_gerada_tem_o_tamanho_pedido, (Linhas, Colunas) == (6, 6)) :-
    set_random(seed(7)),
    gerar(carimbos, 6, 5, fase(Luzes, _)),
    length(Luzes, Linhas),
    Luzes = [Primeira|_],
    length(Primeira, Colunas).

test(classico_so_tem_cruz) :-
    set_random(seed(1)),
    gerar(classico, 5, 4, fase(_, Carimbos)),
    forall(celula(Carimbos, _, Carimbo), Carimbo == cruz).

test(carimbos_nao_tem_trava) :-
    set_random(seed(3)),
    gerar(carimbos, 5, 8, fase(_, Carimbos)),
    \+ celula(Carimbos, _, trava).

test(variante_inexistente, fail) :-
    gerar(nao_existe, 5, 4, _).

test(mais_cliques_do_que_celulas, fail) :-
    gerar(carimbos, 4, 17, _).

%   No clássico 5x5 o mínimo nunca passa de 15: o gerador desiste quando
%   estoura o limite de tempo (este teste demora esse limite).
test(dificuldade_impossivel, fail) :-
    gerar(classico, 5, 16, _).

:- end_tests(gerar).
