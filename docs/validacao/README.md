# Validação da regra própria (protótipo descartável)

Estes arquivos **não são o código do projeto**. Eles existem para provar,
antes de começar, que a regra "carimbos + células travadas" funciona com as
5 features (ver [ADR 0001](../adr/0001-jogo-e-regra-propria.md)). O código
real segue o [design do Prolog](../design-prolog.md), com outros módulos e
nomes.

> Nesta versão a trava é uma **matriz separada** (`fase(Luzes, Carimbos, Travas)`).
> No projeto ela vira um tipo de célula (`trava`), conforme o
> [ADR 0005](../adr/0005-representacao-da-fase.md). A semântica é a mesma.

Origem: protótipo gerado com auxílio de IA (Claude) durante o planejamento.
Declarar na seção 11 do relatório caso algum trecho seja reaproveitado.

## Rodando

```sh
cd docs/validacao
swipl -q -g "t_regressao" -t halt validar.pl
swipl -q -g "t_gerador(5, 0.15, [3,6,9,12], 8)" -t halt validar.pl
swipl -q -g "t_layouts(5, 0.15, 30)" -t halt validar.pl
```

## Resultados (SWI-Prolog 10.0.2, 11/11/2026)

```
regressao classico: solucoes=4 (esperado 4), minimo=11 (esperado 11)

N=5 trava=0.15 dif=3:  corretas=8/8 dicas_ok=8/8 max_solucoes=2  t_gerar med=0.060 max=0.187
N=5 trava=0.15 dif=6:  corretas=8/8 dicas_ok=8/8 max_solucoes=1  t_gerar med=0.072 max=0.150
N=5 trava=0.15 dif=9:  corretas=8/8 dicas_ok=8/8 max_solucoes=2  t_gerar med=0.045 max=0.103
N=5 trava=0.15 dif=12: corretas=8/8 dicas_ok=8/8 max_solucoes=2  t_gerar med=0.043 max=0.098
N=5 trava=0.0  dif=15: corretas=5/5 dicas_ok=5/5 max_solucoes=2  t_gerar med=0.823 max=1.849
N=5 trava=0.3  dif=10: corretas=5/5 dicas_ok=5/5 max_solucoes=2  t_gerar med=0.019 max=0.057
N=6 trava=0.15 dif=8:  corretas=5/5 dicas_ok=5/5 max_solucoes=2  t_gerar med=0.110 max=0.311
N=6 trava=0.15 dif=15: corretas=5/5 dicas_ok=5/5 max_solucoes=2  t_gerar med=0.117 max=0.243
N=7 trava=0.15 dif=10: corretas=4/4 dicas_ok=4/4 max_solucoes=2  t_gerar med=0.114 max=0.242
N=7 trava=0.15 dif=20: corretas=4/4 dicas_ok=4/4 max_solucoes=2  t_gerar med=0.163 max=0.285

layouts aleatorios N=5 trava=0.15: com_solucao=3/30  max_solucoes=2 t_minimo_max=0.119
layouts aleatorios N=5 trava=0.0:  com_solucao=12/30 max_solucoes=4 t_minimo_max=0.409
layouts aleatorios N=7 trava=0.15: com_solucao=0/10  max_solucoes=0
```

- **corretas:** a solução mínima, aplicada pelo simulador `apertar/3`
  (independente do modelo), apaga tudo, e o mínimo é igual à dificuldade pedida.
- **dicas_ok:** depois de aplicar a dica, o mínimo cai exatamente 1.
- **layouts aleatórios:** luzes sorteadas ao acaso raramente têm solução,
  então o gerador por cliques reversos (ADR 0007) é obrigatório.

## O que deu errado no caminho (vale para quem for implementar)

- `findall/3` **copia** variáveis livres. Montar a lista de variáveis de
  aperto dentro de um `findall` faz as restrições não valerem para nada.
- Lambdas `yall` (`[X]>>...`) em arquivo compilado tratam variáveis externas
  como novas, a menos que sejam declaradas (`Free/[X]>>...`). Use predicados
  auxiliares.
- `weighted_maximum/3` da `clpb` para achar o mínimo passou de 120 s no 5x5.
  Enumerar as soluções (no máximo 4) é instantâneo.
