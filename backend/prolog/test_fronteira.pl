/*  test_fronteira.pl: testes plunit de fronteira.pl.

    Rodar: make test-prolog

    Aqui os carimbos chegam como STRINGS ("cruz"), do jeito que o janus os
    entrega quando vêm do Python.
*/

% Um módulo próprio isola os predicados auxiliares deste arquivo dos
% outros arquivos de teste, que são carregados juntos.
:- module(test_fronteira, []).

:- use_module(fronteira).
:- use_module(library(plunit)).
:- use_module(library(apply)).
:- use_module(library(random)).

so_cruz(Textos) :-
    length(Fileira, 5), maplist(=("cruz"), Fileira),
    length(Textos, 5), maplist(=(Fileira), Textos).

centro_aceso([[0,0,0,0,0], [0,0,0,0,0], [0,0,1,0,0], [0,0,0,0,0], [0,0,0,0,0]]).
canto_aceso([[1,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]]).
apagado([[0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]]).


:- begin_tests(fronteira).

test(gerar_devolve_atomos_e_numeros) :-
    set_random(seed(42)),
    gerar("carimbos_travas", 5, 6, Luzes, Carimbos),
    Luzes = [[Luz|_]|_], integer(Luz),
    Carimbos = [[Carimbo|_]|_], atom(Carimbo).

test(gerar_variante_invalida, fail) :-
    gerar("nao_existe", 5, 6, _, _).

test(verificar, Resultado == [4, 11]) :-
    centro_aceso(Luzes), so_cruz(Carimbos),
    verificar(Luzes, Carimbos, Resultado).

test(verificar_sem_solucao, Resultado == sem_solucao) :-
    canto_aceso(Luzes), so_cruz(Carimbos),
    verificar(Luzes, Carimbos, Resultado).

test(dica_vira_lista, Resultado = [_, _]) :-
    centro_aceso(Luzes), so_cruz(Carimbos),
    dica(Luzes, Carimbos, Resultado).

test(dica_resolvida, Resultado == resolvida) :-
    apagado(Luzes), so_cruz(Carimbos),
    dica(Luzes, Carimbos, Resultado).

test(resolver, (Total, Minimo) == (11, 11)) :-
    centro_aceso(Luzes), so_cruz(Carimbos),
    resolver(Luzes, Carimbos, [Cliques, Minimo]),
    length(Cliques, Total).

test(resolver_sem_solucao, Resultado == sem_solucao) :-
    canto_aceso(Luzes), so_cruz(Carimbos),
    resolver(Luzes, Carimbos, Resultado).

test(carimbo_desconhecido, error(domain_error(carimbo, estrela))) :-
    centro_aceso(Luzes), so_cruz([Fileira|Resto]),
    Fileira = [_|Outras],
    verificar(Luzes, [["estrela"|Outras]|Resto], _).

:- end_tests(fronteira).
