/*  regras.pl: base de conhecimento do jogo.

    Aqui mora o que o jogo É: quais carimbos existem, quais células cada um
    inverte e o que acontece num clique. Os outros módulos (solver, gerador)
    só usam estes predicados.

    REPRESENTAÇÃO
    -------------
    Uma fase é o termo fase(Luzes, Carimbos), com duas matrizes NxN:

        Luzes:    0 = apagada, 1 = acesa
        Carimbos: cruz, xis, linha, coluna, bloco ou trava

    Uma posição é o par Linha-Coluna, contando a partir de 0.

    A tabela de deslocamentos abaixo é a FONTE ÚNICA da regra do jogo: o Elm
    (frontend/src/Fase.elm) implementa exatamente a mesma tabela.
*/

:- module(regras,
          [ carimbo/1,          % ?Nome
            deslocamentos/2,    % ?Nome, ?Deslocamentos
            celula/3,           % ?Matriz, ?Posicao, ?Valor
            afeta/3,            % +Carimbos, ?Clicada, ?Afetada
            apertar/3,          % +Posicao, +Fase, -NovaFase
            resolvida/1         % +Fase
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).


/* =========================================================================
   Carimbos
   ========================================================================= */

%!  carimbo(?Nome) is nondet.
%
%   Os tipos de célula que existem no jogo.
carimbo(cruz).
carimbo(xis).
carimbo(linha).
carimbo(coluna).
carimbo(bloco).
carimbo(trava).

%!  deslocamentos(?Nome, ?Deslocamentos) is nondet.
%
%   As células que um carimbo inverte, relativas à célula clicada, como pares
%   DLinha-DColuna. Todo carimbo inverte a própria célula (0-0). A trava não
%   pode ser clicada, então não inverte nada.
deslocamentos(cruz,   [0-0, -1-0, 1-0, 0-(-1), 0-1]).
deslocamentos(xis,    [0-0, -1-(-1), -1-1, 1-(-1), 1-1]).
deslocamentos(linha,  [0-0, 0-(-1), 0-1, 0-(-2), 0-2]).
deslocamentos(coluna, [0-0, -1-0, 1-0, -2-0, 2-0]).
deslocamentos(bloco,  [-1-(-1), -1-0, -1-1,
                        0-(-1),  0-0,  0-1,
                        1-(-1),  1-0,  1-1]).
deslocamentos(trava,  []).


/* =========================================================================
   Matrizes
   ========================================================================= */

%!  celula(?Matriz, ?Posicao, ?Valor) is nondet.
%
%   Valor está na Posicao da Matriz. Com a posição livre, enumera todas as
%   células por backtracking (nth0/3 funciona nos dois sentidos).
celula(Matriz, Linha-Coluna, Valor) :-
    nth0(Linha, Matriz, Fileira),
    nth0(Coluna, Fileira, Valor).


/* =========================================================================
   Quem afeta quem
   ========================================================================= */

%!  afeta(+Carimbos, ?Clicada, ?Afetada) is nondet.
%
%   Clicar na posição Clicada inverte a luz da posição Afetada.
%
%   É uma RELAÇÃO, não uma função: serve para perguntar "quem eu inverto?"
%   (Clicada conhecida) e também "quem me inverte?" (Afetada conhecida). O
%   solver usa o segundo sentido para montar uma restrição por luz.
%
%   Deslocamentos que caem fora do tabuleiro são ignorados.
afeta(Carimbos, Linha-Coluna, LinhaAfetada-ColunaAfetada) :-
    celula(Carimbos, Linha-Coluna, Carimbo),
    deslocamentos(Carimbo, Deslocamentos),
    member(DLinha-DColuna, Deslocamentos),
    LinhaAfetada is Linha + DLinha,
    ColunaAfetada is Coluna + DColuna,
    dentro(Carimbos, LinhaAfetada-ColunaAfetada).

dentro(Matriz, Linha-Coluna) :-
    length(Matriz, N),
    Linha >= 0, Linha < N,
    Coluna >= 0, Coluna < N.


/* =========================================================================
   Um clique
   ========================================================================= */

%!  apertar(+Posicao, +Fase, -NovaFase) is semidet.
%
%   NovaFase é Fase depois de um clique em Posicao. Falha se a célula for
%   uma trava, que não pode ser clicada.
%
%   A ordem dos argumentos (Posicao primeiro) permite usar foldl/4 para
%   aplicar uma lista de cliques: foldl(apertar, Cliques, Fase0, Fase).
apertar(Posicao, fase(Luzes, Carimbos), fase(NovasLuzes, Carimbos)) :-
    celula(Carimbos, Posicao, Carimbo),
    Carimbo \== trava,
    findall(Afetada, afeta(Carimbos, Posicao, Afetada), Afetadas),
    findall(NovaFileira,
            ( nth0(Linha, Luzes, Fileira),
              findall(NovaLuz,
                      ( nth0(Coluna, Fileira, Luz),
                        luz_depois(Linha-Coluna, Afetadas, Luz, NovaLuz) ),
                      NovaFileira) ),
            NovasLuzes).

luz_depois(Posicao, Afetadas, Luz, NovaLuz) :-
    (   memberchk(Posicao, Afetadas)
    ->  NovaLuz is 1 - Luz
    ;   NovaLuz = Luz
    ).

%!  resolvida(+Fase) is semidet.
%
%   Todas as luzes estão apagadas.
resolvida(fase(Luzes, _Carimbos)) :-
    maplist(maplist(==(0)), Luzes).
