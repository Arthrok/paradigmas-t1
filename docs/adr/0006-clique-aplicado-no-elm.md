# ADR 0006: O clique é aplicado no Elm, e o raciocínio fica no Prolog

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

Cada chamada ao Prolog leva ~0,1–0,4 s (ADR 0004). Se cada clique fosse ao
servidor, o jogo pareceria travado.

## Decisão

- **O Elm aplica o clique localmente**, com uma função pura
  `Fase.apertar : Posicao -> Fase -> Fase`. O template do professor faz o
  mesmo com as regras instantâneas do Sudoku.
- **O Prolog só é chamado para raciocinar:** verificar (F1), dar dica (F2),
  achar a solução mínima (F3) e gerar fase (F4/F5).
- A regra de "quem afeta quem" existe nas duas linguagens:
  `afeta/4` em `regras.pl` e `Fase.apertar` em `Fase.elm`.

## Consequências

- **Risco:** as duas implementações podem divergir. Mitigação:
  - os deslocamentos de cada carimbo ficam documentados num único lugar
    (`docs/design-prolog.md`), e as duas implementações apontam para ele;
  - testes de propriedade nos dois lados: fuzz no Elm (`apertar` 2x =
    identidade, comutatividade) e plunit no Prolog (simulador × solver).
- **Ganho para o relatório:** comparar as duas versões da mesma regra é
  ótimo material para a seção 13. No Prolog a regra é uma **relação**
  usada para *resolver*; no Elm é uma **função** usada para *aplicar*.
