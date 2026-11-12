# ADR 0003: O estado do jogo fica no Elm, e o Prolog não guarda estado

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

Alguém precisa guardar o tabuleiro atual, o histórico de cliques e o modo do
jogo. As opções são o Elm (cliente) ou o Prolog (servidor, com
`assert/retract`).

## Decisão

- O **Elm guarda todo o estado** no `Model`.
- O **Prolog não guarda estado**: cada chamada recebe a fase completa e
  devolve uma resposta. Nada de `assert/retract`, `nb_setval` ou sessão.
- O Python também não guarda estado.

## Consequências

- Os dois lados ficam **puros**, o que é um bom argumento nas seções 5.2,
  6.2 e 13 do relatório.
- Desfazer/refazer sai de graça no Elm: o histórico é uma lista de fases
  imutáveis.
- Dá para testar cada predicado isoladamente no `swipl`, sem preparar estado.
- Cada requisição manda a fase inteira (≤ 7x7, então uns poucos KB, o que é
  irrelevante).
- O clique precisa ser aplicado no Elm para a resposta ser instantânea (ver
  ADR 0006).
