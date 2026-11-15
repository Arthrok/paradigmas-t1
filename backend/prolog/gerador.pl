/*  gerador.pl: cria fases novas (F4) em cada variante do jogo (F5).

    O ALGORITMO (docs/adr/0007-gerador-por-cliques-reversos.md)
    ----------------------------------------------------------
    Sortear luzes ao acaso quase sempre gera fases sem solução. Fazemos o
    caminho inverso:

        1. sorteamos os carimbos de cada célula, conforme a variante;
        2. partimos do tabuleiro APAGADO e aplicamos K cliques sorteados.
           Como cada clique pode ser desfeito, a fase com certeza tem solução;
        3. conferimos com o solver se a solução MÍNIMA tem exatamente K
           cliques. Às vezes os cliques sorteados têm um atalho, e aí a fase
           seria mais fácil do que o pedido: descartamos e tentamos de novo.

    Assim, "dificuldade" tem um significado preciso: o número mínimo de
    cliques para resolver a fase.
*/

:- module(gerador,
          [ variante/3,         % ?Nome, ?Formas, ?ChanceDeTrava
            gerar/4             % +Variante, +Tamanho, +Dificuldade, -Fase
          ]).

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(library(time)).
:- use_module(regras).
:- use_module(solver).


%!  variante(?Nome, ?Formas, ?ChanceDeTrava) is nondet.
%
%   Cada variante diz quais carimbos podem aparecer e a chance de uma célula
%   ser uma trava. Uma variante nova é só mais um fato: o resto do gerador e
%   o solver inteiro continuam iguais.
variante(classico,        [cruz],                            0.0).
variante(carimbos,        [cruz, xis, linha, coluna, bloco], 0.0).
variante(carimbos_travas, [cruz, xis, linha, coluna, bloco], 0.15).

%   Algumas dificuldades são impossíveis (no clássico 5x5 o mínimo nunca
%   passa de 15). Para não tentar para sempre, o gerador desiste depois deste
%   tempo.
limite_de_segundos(5).


%!  gerar(+Variante, +Tamanho, +Dificuldade, -Fase) is semidet.
%
%   Fase é uma fase nova Tamanho x Tamanho, da Variante, cuja solução mínima
%   tem exatamente Dificuldade cliques. Falha se a variante não existe ou se
%   não conseguir gerar dentro do limite de tempo.
gerar(Variante, Tamanho, Dificuldade, Fase) :-
    variante(Variante, Formas, ChanceDeTrava),
    Dificuldade =< Tamanho * Tamanho,
    limite_de_segundos(Limite),
    catch(call_with_time_limit(Limite,
                               tentar_ate_conseguir(Formas, ChanceDeTrava, Tamanho,
                                                    Dificuldade, Fase)),
          time_limit_exceeded,
          fail).

%   repeat/0 cria infinitos pontos de escolha: a cada falha de tentativa/5,
%   o Prolog volta ao repeat e tenta de novo. O corte encerra o laço na
%   primeira tentativa que der certo.
tentar_ate_conseguir(Formas, ChanceDeTrava, Tamanho, Dificuldade, Fase) :-
    repeat,
    tentativa(Formas, ChanceDeTrava, Tamanho, Dificuldade, Fase),
    !.

tentativa(Formas, ChanceDeTrava, Tamanho, Dificuldade, Fase) :-
    matriz(Tamanho, sortear_carimbo(Formas, ChanceDeTrava), Carimbos),
    matriz(Tamanho, =(0), Apagado),
    sortear_cliques(Carimbos, Dificuldade, Cliques),
    foldl(apertar, Cliques, fase(Apagado, Carimbos), Fase),
    solucao_minima(Fase, _, Minimo),
    Minimo =:= Dificuldade.


/* =========================================================================
   Sorteios
   ========================================================================= */

sortear_carimbo(Formas, ChanceDeTrava, Carimbo) :-
    random(Sorteio),
    (   Sorteio < ChanceDeTrava
    ->  Carimbo = trava
    ;   random_member(Carimbo, Formas)
    ).

%   Quantidade células clicáveis diferentes, em ordem aleatória. Falha se
%   não houver células clicáveis suficientes.
sortear_cliques(Carimbos, Quantidade, Cliques) :-
    findall(Posicao,
            ( celula(Carimbos, Posicao, Carimbo), Carimbo \== trava ),
            Clicaveis),
    random_permutation(Clicaveis, Embaralhadas),
    length(Cliques, Quantidade),
    append(Cliques, _, Embaralhadas).

%   matriz(+N, :Gerador, -Matriz): matriz NxN em que cada célula é obtida
%   chamando Gerador.
matriz(N, Gerador, Matriz) :-
    length(Matriz, N),
    maplist(fileira(N, Gerador), Matriz).

fileira(N, Gerador, Fileira) :-
    length(Fileira, N),
    maplist(Gerador, Fileira).
