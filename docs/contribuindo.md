# Como contribuir

Resumo do [ADR 0008](adr/0008-fluxo-git-e-convencoes.md), na prática.

## Pegando uma issue

1. Veja o [plano de issues](plano-de-issues.md) e confira se as dependências
   da sua issue já estão fechadas. Se não estiverem, dá para começar seguindo
   o [contrato da API](api.md) e os docs de design, usando dados fixos (mock).
2. Comente na issue que começou. Se travar por mais de meio dia, avise no
   grupo.

## Branch, commit, PR

```sh
git switch main && git pull
git switch -c feat/7-gerador          # <tipo>/<nº-issue>-<resumo>

# ... trabalha ...
make test                             # tudo passando
make format                           # se mexeu em Elm

git add -p
git commit -m "feat(prolog): gera fase por cliques reversos"
git push -u origin feat/7-gerador
gh pr create --fill                   # no corpo: "Closes #7"
```

| Tipo | Quando |
|---|---|
| `feat` | funcionalidade nova |
| `fix` | correção de bug |
| `test` | só testes |
| `docs` | documentação ou relatório |
| `refactor` | muda o código sem mudar o comportamento |
| `chore` | configuração, dependências, CI |

Escopos: `prolog`, `elm`, `backend`, `infra`, `docs`, `relatorio`.

## Revisão

- Todo PR precisa de **1 aprovação** de alguém que não é o autor.
- Quem revisa: baixa a branch, roda `make test`, e se for UI, abre o jogo.
- Prefira PRs pequenos (≤ ~300 linhas). É mais fácil de revisar e de
  explicar na apresentação.

## Definição de pronto

- [ ] `make test` passa
- [ ] Elm formatado (`elm-format --validate`) / `swipl` carrega sem avisos
- [ ] código novo tem teste
- [ ] comentários explicam decisões (o "porquê"), não repetem o código
- [ ] se mudou o contrato ou uma decisão: `docs/api.md` ou um ADR atualizado
- [ ] o autor consegue **explicar cada linha** (o professor pergunta na apresentação, seção 2.1 da avaliação)

## Uso de IA

Vale usar, mas **registre**: anote na issue ou no PR o que foi gerado com IA.
Isso alimenta a tabela da seção 11 do relatório. Não declarar zera o
trabalho; declarar não tira pontos.
