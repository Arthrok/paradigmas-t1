/*  fronteira.pl: a API pública do Prolog, o único módulo que o Python chama.

    Os outros módulos trabalham com termos Prolog (fase(Luzes, Carimbos),
    posições Linha-Coluna, átomos). O janus, que liga Python e Prolog, só
    converte listas, números, strings e átomos. Este módulo traduz entre os
    dois mundos e não tem nenhuma regra do jogo:

        Python -> Prolog   strings ("cruz") viram átomos (cruz)
        Prolog -> Python   posições L-C viram listas [L, C]

    Cada predicado corresponde a uma rota de docs/api.md. Os resultados
    "sem solução" e "já resolvida" são átomos (chegam ao Python como
    strings), e o Python os transforma em respostas 422.
*/

:- module(fronteira,
          [ gerar/5,            % +Variante, +Tamanho, +Dificuldade, -Luzes, -Carimbos
            verificar/3,        % +Luzes, +Carimbos, -Resultado
            dica/3,             % +Luzes, +Carimbos, -Resultado
            resolver/3          % +Luzes, +Carimbos, -Resultado
          ]).

:- use_module(library(apply)).
:- use_module(library(error)).
:- use_module(regras).
:- use_module(solver).
:- use_module(gerador).


%!  gerar(+Variante:string, +Tamanho, +Dificuldade, -Luzes, -Carimbos) is semidet.
%
%   F4 + F5. Falha se não conseguir gerar a fase. A solução mínima da fase
%   gerada tem exatamente Dificuldade cliques (garantido pelo gerador).
gerar(TextoVariante, Tamanho, Dificuldade, Luzes, Carimbos) :-
    atom_string(Variante, TextoVariante),
    gerador:gerar(Variante, Tamanho, Dificuldade, fase(Luzes, Carimbos)).

%!  verificar(+Luzes, +Carimbos:list(list(string)), -Resultado) is det.
%
%   F1. Resultado é [Solucoes, Minimo] ou sem_solucao.
verificar(Luzes, Textos, Resultado) :-
    fase(Luzes, Textos, Fase),
    (   solucao_minima(Fase, _, Minimo)
    ->  num_solucoes(Fase, Solucoes),
        Resultado = [Solucoes, Minimo]
    ;   Resultado = sem_solucao
    ).

%!  dica(+Luzes, +Carimbos:list(list(string)), -Resultado) is det.
%
%   F2. Resultado é [Linha, Coluna], resolvida ou sem_solucao.
dica(Luzes, Textos, Resultado) :-
    fase(Luzes, Textos, Fase),
    solver:dica(Fase, Dica),
    (   Dica = Linha-Coluna
    ->  Resultado = [Linha, Coluna]
    ;   Resultado = Dica
    ).

%!  resolver(+Luzes, +Carimbos:list(list(string)), -Resultado) is det.
%
%   F3. Resultado é [Cliques, Minimo], com Cliques = [[Linha, Coluna], ...],
%   ou sem_solucao.
resolver(Luzes, Textos, Resultado) :-
    fase(Luzes, Textos, Fase),
    (   solucao_minima(Fase, Posicoes, Minimo)
    ->  maplist(posicao_lista, Posicoes, Cliques),
        Resultado = [Cliques, Minimo]
    ;   Resultado = sem_solucao
    ).


/* =========================================================================
   Conversões
   ========================================================================= */

fase(Luzes, Textos, fase(Luzes, Carimbos)) :-
    maplist(maplist(texto_carimbo), Textos, Carimbos).

%   O Python já valida os nomes, então um nome desconhecido aqui é um bug:
%   lançamos um erro em vez de simplesmente falhar.
texto_carimbo(Texto, Carimbo) :-
    atom_string(Carimbo, Texto),
    (   carimbo(Carimbo)
    ->  true
    ;   domain_error(carimbo, Carimbo)
    ).

posicao_lista(Linha-Coluna, [Linha, Coluna]).
