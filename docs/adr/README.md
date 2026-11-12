# Registros de decisão de arquitetura (ADRs)

Cada ADR registra **uma** decisão: contexto, decisão, alternativas e
consequências. Para mudar uma decisão, crie um ADR novo que substitua o
antigo, e marque o antigo como `substituída por 00XX`.

| ADR | Decisão |
|-----|---------|
| [0001](0001-jogo-e-regra-propria.md) | Jogo escolhido, regra própria (carimbos + travas) e as 5 features |
| [0002](0002-base-no-template.md) | Partir do template do professor (Elm + FastAPI/janus + SWI-Prolog) |
| [0003](0003-estado-no-elm.md) | Estado no Elm; Prolog e Python sem estado |
| [0004](0004-modelo-clpb.md) | Modelo de restrições booleanas com `clpb` |
| [0005](0005-representacao-da-fase.md) | Representação da fase em JSON, Prolog e Elm |
| [0006](0006-clique-aplicado-no-elm.md) | Clique aplicado no Elm, raciocínio no Prolog |
| [0007](0007-gerador-por-cliques-reversos.md) | Gerador por cliques reversos com dificuldade verificada |
| [0008](0008-fluxo-git-e-convencoes.md) | Fluxo Git, revisão e definição de pronto |

Modelo para um ADR novo:

```markdown
# ADR 00XX: Título curto

- **Status:** proposta | aceita | substituída por 00YY
- **Data:** AAAA-MM-DD

## Contexto
## Decisão
## Alternativas consideradas
## Consequências
```
