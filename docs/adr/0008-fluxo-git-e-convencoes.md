# ADR 0008: Fluxo de trabalho no Git e convenções de código

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

São 6 pessoas trabalhando em paralelo por uma semana. A rubrica mede
`elm-format`, avisos do `swipl`, testes e distribuição de commits por autor
(confrontada com a avaliação 360).

## Decisão

- **Uma issue = uma branch = um PR.** Nome da branch:
  `<tipo>/<nº-da-issue>-<resumo>`, por exemplo `feat/7-gerador`,
  `docs/21-relatorio-prolog`.
- **Commits** no estilo Conventional Commits, em português:
  `feat(prolog): adiciona gerador por cliques reversos`.
  Os tipos são `feat`, `fix`, `test`, `docs`, `refactor`, `chore`.
- **PR** com `Closes #N` e **pelo menos 1 revisão** de outra pessoa antes do
  merge na `main`. Quem revisa roda os testes localmente.
- **Cada pessoa commita o próprio código.** Nada de uma pessoa subir o código
  de todo mundo: a distribuição de commits é conferida contra a seção 10.
- **Definição de pronto** de uma issue:
  - `make test` passa;
  - `elm-format --validate` passa (Elm) e o `swipl` carrega sem avisos (Prolog);
  - funções e predicados novos têm teste;
  - comentários explicam *decisões*, não repetem o código;
  - docs atualizados se o contrato mudou.

Detalhes práticos em [`docs/contribuindo.md`](../contribuindo.md).

## Consequências

- O histórico do Git vira evidência para as seções 10 e 13 do relatório.
- A `main` fica sempre funcionando: dá para demonstrar a qualquer momento.
