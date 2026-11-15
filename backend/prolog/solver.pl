/*  solver.pl: o jogo como um sistema de restrições booleanas.

    A IDEIA
    -------
    Duas propriedades do jogo simplificam tudo:

        1. a ordem dos cliques não importa;
        2. clicar duas vezes na mesma célula é o mesmo que não clicar.

    Então uma solução não é uma SEQUÊNCIA de cliques, e sim um CONJUNTO: para
    cada célula, uma variável booleana A que diz "clico aqui ou não".

    Uma luz termina apagada quando é invertida um número ímpar de vezes se
    começou acesa, e um número par de vezes se começou apagada. Em lógica
    booleana, "ímpar" é o XOR (#). Para cada luz:

        A1 # A2 # ... # Ak  =:=  LuzInicial

    onde A1..Ak são os apertos das células cujo carimbo afeta essa luz.

    Não escrevemos nenhum algoritmo de busca: só DECLARAMOS essas equações
    com a library(clpb), e o resolvedor de restrições encontra as soluções.
    Um único modelo sustenta três features:

        F1  num_solucoes/2     quantas soluções a fase tem
        F2  dica/2             um próximo clique correto
        F3  solucao_minima/3   a solução com menos cliques

    Veja docs/adr/0004-modelo-clpb.md para as alternativas descartadas.
*/

:- module(solver,
          [ modelo/2,           % +Fase, -Apertos
            num_solucoes/2,     % +Fase, -Quantidade
            solucao/3,          % +Fase, -Cliques, -Total
            solucao_minima/3,   % +Fase, -Cliques, -Total
            dica/2              % +Fase, -Resultado
          ]).

:- use_module(library(clpb)).
:- use_module(library(apply)).
:- use_module(library(aggregate)).
:- use_module(regras).


/* =========================================================================
   O modelo
   ========================================================================= */

%!  modelo(+Fase, -Apertos) is semidet.
%
%   Apertos é uma matriz NxN de variáveis booleanas (1 = clicar na célula)
%   que obedece às restrições da Fase. Falha se a fase não tem solução: o
%   clpb detecta a contradição já ao registrar as restrições.
modelo(fase(Luzes, Carimbos), Apertos) :-
    maplist(maplist(aperto_permitido), Carimbos, Apertos),
    findall(Posicao, celula(Luzes, Posicao, _), Posicoes),
    maplist(restricao_da_luz(Luzes, Carimbos, Apertos), Posicoes).

%   Uma trava não pode ser clicada: o aperto dela é sempre 0. Nas demais
%   células o aperto fica livre (uma variável nova).
aperto_permitido(Carimbo, Aperto) :-
    (   Carimbo == trava
    ->  Aperto = 0
    ;   true
    ).

%   A restrição de uma luz: o XOR dos apertos que a afetam é igual ao seu
%   estado inicial.
%
%   Atenção: findall/3 COPIA variáveis livres. Por isso o findall coleta só
%   POSIÇÕES (valores concretos), e as variáveis de aperto são buscadas
%   depois, fora dele, com maplist.
restricao_da_luz(Luzes, Carimbos, Apertos, Posicao) :-
    celula(Luzes, Posicao, Luz),
    findall(Quem, afeta(Carimbos, Quem, Posicao), Quems),
    maplist(celula(Apertos), Quems, ApertosQueAfetam),
    foldl(xor, ApertosQueAfetam, 0, Paridade),
    sat(Paridade =:= Luz).

xor(Aperto, Acumulado, Acumulado # Aperto).


/* =========================================================================
   F1: verificar solução
   ========================================================================= */

%!  num_solucoes(+Fase, -Quantidade) is det.
%
%   Quantas soluções diferentes a Fase tem (0 se nenhuma).
%
%   sat_count/2 conta as soluções direto no modelo, sem enumerá-las. A
%   expressão +[1|Vars] é sempre verdadeira; ela só informa QUAIS variáveis
%   entram na contagem.
num_solucoes(Fase, Quantidade) :-
    (   modelo(Fase, Apertos)
    ->  term_variables(Apertos, Vars),
        sat_count(+[1|Vars], Quantidade)
    ;   Quantidade = 0
    ).


/* =========================================================================
   F3: solução mínima
   ========================================================================= */

%!  solucao(+Fase, -Cliques, -Total) is nondet.
%
%   Cliques é uma solução da Fase: as posições a clicar, em ordem de linha e
%   coluna. Total é a quantidade de cliques. Por backtracking, enumera todas
%   as soluções.
solucao(Fase, Cliques, Total) :-
    modelo(Fase, Apertos),
    term_variables(Apertos, Vars),
    labeling(Vars),
    findall(Posicao, celula(Apertos, Posicao, 1), Cliques),
    length(Cliques, Total).

%!  solucao_minima(+Fase, -Cliques, -Total) is semidet.
%
%   A solução com menos cliques. Falha se a fase não tem solução.
%
%   Basta enumerar as soluções e ficar com a menor: nas fases do jogo há no
%   máximo 4 soluções (ver docs/validacao).
solucao_minima(Fase, Cliques, Total) :-
    aggregate_all(min(T, C), solucao(Fase, C, T), min(Total, Cliques)).


/* =========================================================================
   F2: dica
   ========================================================================= */

%!  dica(+Fase, -Resultado) is det.
%
%   Resultado é um dos três:
%
%       Linha-Coluna   uma célula que faz parte da solução mínima;
%       resolvida      todas as luzes já estão apagadas;
%       sem_solucao    não existe sequência de cliques que resolva a fase.
%
%   Como a ordem dos cliques não importa, QUALQUER célula da solução é um
%   próximo passo correto, a partir do estado atual do jogador.
dica(Fase, Resultado) :-
    (   resolvida(Fase)
    ->  Resultado = resolvida
    ;   solucao_minima(Fase, [Primeira|_], _)
    ->  Resultado = Primeira
    ;   Resultado = sem_solucao
    ).
