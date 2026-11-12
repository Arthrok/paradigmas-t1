# ADR 0002: Partir do template do professor

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

O professor publicou um projeto de exemplo (Sudoku) com servidor, integração
Prolog e frontend Elm prontos:
<https://github.com/fabiommendes/paradigmas-trabalho-final>. O README dele
convida a usar a estrutura como ponto de partida. O Python **não é avaliado**,
e a rubrica considera um alerta Python acima de ~30% do código.

## Decisão

Usar a mesma stack e estrutura do template:

| Camada | Tecnologia | Papel |
|---|---|---|
| Frontend | Elm 0.19.1 + Vite + Tailwind/daisyUI | interface, estado do jogo |
| Ponte | Python + FastAPI + janus | só traduz HTTP ↔ predicados |
| Lógica | SWI-Prolog (≥ 9.2) + `library(clpb)` | regras, solver, gerador |

O código do Sudoku é removido. Ficam a infraestrutura (Makefile, Vite, proxy
`/api`, janus) e os padrões (módulos Elm, testes plunit e pytest).

## Alternativas consideradas

- **Servidor HTTP direto no SWI-Prolog** (`library(http/...)`): elimina o
  Python, mas temos que reconstruir a infraestrutura que o template já
  entrega, e mistura código de servidor no Prolog avaliado.
- **Começar do zero:** mais tempo, nenhum ganho na nota.

## Consequências

- A origem fica declarada na seção 11 do relatório. Reaproveitamento
  declarado é permitido.
- Isso não conta como "variante do Sudoku": o domínio é outro (ver ADR 0001).
- O Python segue a regra **sem lógica de jogo**: só validação de forma
  (pydantic) e chamada aos predicados.
