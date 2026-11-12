:- ['carimbos.pl'].

tempo(G, T) :- statistics(cputime, A), once(G), statistics(cputime, B), T is B-A.

todos([cruz, xis, linha, coluna, bloco]).

% 1) Regressão: só cruz, sem travas = Lights Out clássico
t_regressao :-
    matriz(5, =(cruz), C), matriz(5, =(0), T),
    L = [[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    num_solucoes(fase(L,C,T), NS), solucao_minima(fase(L,C,T), _, K),
    format("regressao classico: solucoes=~w (esperado 4), minimo=~w (esperado 11)~n", [NS, K]).

% 2) Gerar várias fases e validar corretude + dica + dificuldade
t_gerador(N, PctTrava, Difs, Reps) :-
    todos(Ks),
    forall(member(D, Difs),
      ( findall(TG-ok(Okc, Okd, NS),
          ( between(1, Reps, _),
            tempo(gerar(N, Ks, PctTrava, D, F), TG),
            solucao_minima(F, P, Min),
            aplicar_solucao(F, P, F2), ( apagado(F2), Min =:= D -> Okc = 1 ; Okc = 0 ),
            dica(F, H), apertar(F, H, FH), solucao_minima(FH, _, MinH),
            ( MinH =:= Min - 1 -> Okd = 1 ; Okd = 0 ),
            num_solucoes(F, NS) ),
          Rs),
        pairs_keys_values(Rs, Ts, Oks),
        max_list(Ts, TMax), sum_list(Ts, TS), length(Ts, Len), TMed is TS/Len,
        aggregate_all(sum(X), member(ok(X,_,_), Oks), SC),
        aggregate_all(sum(X), member(ok(_,X,_), Oks), SD),
        aggregate_all(max(X), member(ok(_,_,X), Oks), MaxNS),
        format("N=~w trava=~w dif=~w: corretas=~w/~w dicas_ok=~w/~w max_solucoes=~w  t_gerar med=~3f max=~3f~n",
               [N, PctTrava, D, SC, Len, SD, Len, MaxNS, TMed, TMax]) )).

% 3) Pior caso de enumeração: layouts aleatórios, quantas soluções / tempo do mínimo
t_layouts(N, PctTrava, Reps) :-
    todos(Ks),
    findall(NS-T-Solv,
      ( between(1, Reps, _),
        matriz(N, random_member_(Ks), C), matriz(N, sorteia_trava(PctTrava), Tr),
        matriz(N, bit, L), F = fase(L, C, Tr),
        num_solucoes(F, NS),
        ( NS > 0 -> tempo(solucao_minima(F,_,_), T), Solv = 1 ; T = 0, Solv = 0 ) ),
      Rs),
    aggregate_all(max(NS), member(NS-_-_, Rs), MaxNS),
    aggregate_all(max(T), member(_-T-_, Rs), MaxT),
    aggregate_all(sum(S), member(_-_-S, Rs), NSolv), length(Rs, Len),
    format("layouts aleatorios N=~w trava=~w: com_solucao=~w/~w max_solucoes=~w t_minimo_max=~3f~n",
           [N, PctTrava, NSolv, Len, MaxNS, MaxT]).

bit(X) :- X is random(2).
