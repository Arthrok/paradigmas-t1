# Contrato da API

> **Este é o documento que permite trabalhar em paralelo.** Elm, Python e
> Prolog podem ser desenvolvidos ao mesmo tempo seguindo este contrato. Para
> mudá-lo, abra um PR que altere este arquivo e avise o grupo.

Todas as rotas usam `POST`, recebem e devolvem JSON, e ficam sob `/api` (o Vite
repassa para a porta 8000).

## Tipos comuns

### `Fase`

```json
{
  "luzes":    [[0, 1, 0, 0, 0], [1, 1, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 1, 0], [0, 0, 0, 0, 0]],
  "carimbos": [["cruz", "xis", "trava", "linha", "cruz"],
               ["bloco", "cruz", "coluna", "xis", "cruz"],
               ["cruz", "cruz", "cruz", "cruz", "trava"],
               ["linha", "xis", "cruz", "bloco", "cruz"],
               ["cruz", "coluna", "cruz", "cruz", "xis"]]
}
```

| Campo | Regra |
|---|---|
| `luzes` | matriz NxN de inteiros 0/1, onde 1 = acesa |
| `carimbos` | matriz NxN com `"cruz"`, `"xis"`, `"linha"`, `"coluna"`, `"bloco"` ou `"trava"` |
| N | de 4 a 6, e as duas matrizes têm o mesmo N |

### `Posicao`

```json
[2, 3]
```

`[linha, coluna]`, com índice a partir de 0.

### Erro

Todo erro de regra de negócio responde **422** com:

```json
{ "detail": "mensagem legível para mostrar ao jogador" }
```

Erros de forma (JSON malformado, matriz não quadrada, tipo errado) respondem
**422** pelo pydantic (formato padrão do FastAPI). O Elm trata os dois como
`Falha`.

---

## `POST /api/gerar` (F4 + F5)

Gera uma fase nova que com certeza tem solução, com dificuldade exata.

**Requisição**

```json
{ "tamanho": 5, "dificuldade": 8, "variante": "carimbos_travas" }
```

| Campo | Regra |
|---|---|
| `tamanho` | 4 a 6 |
| `dificuldade` | ≥ 1, é o número mínimo de cliques da fase gerada |
| `variante` | `"classico"` (só cruz), `"carimbos"` (cinco formas), `"carimbos_travas"` (cinco formas + ~15% de travas) |

**Resposta 200**

```json
{ "fase": { "luzes": [[...]], "carimbos": [[...]] }, "minimo": 8 }
```

**Erros 422**

- `"Não foi possível gerar uma fase com essa dificuldade."` quando o gerador
  não consegue em 5 s (ADR 0007). Acontece com dificuldades impossíveis para o
  tamanho, como 16 no clássico 5x5.
- Parâmetro fora da faixa ou variante desconhecida.

**Tempo esperado:** com carimbos, 0,02–1 s. No `classico` é mais lento: ~0,5 s no 5x5 e 2–3,5 s no 6x6. Os níveis pré-definidos do Elm ficam dentro desses tempos (ver `design-elm.md`).

---

## `POST /api/verificar` (F1)

Diz se a fase tem solução e quantas. Usado pelo editor de fases.

**Requisição**

```json
{ "fase": { "luzes": [[...]], "carimbos": [[...]] } }
```

**Resposta 200**

```json
{ "solucoes": 4, "minimo": 11 }
```

```json
{ "solucoes": 0, "minimo": null }
```

"Sem solução" **não** é erro: é uma resposta válida (`solucoes: 0`).

---

## `POST /api/dica` (F2)

Sugere um próximo clique correto a partir do estado **atual**.

**Requisição:** `{ "fase": Fase }`

**Resposta 200**

```json
{ "linha": 0, "coluna": 3 }
```

**Erros 422**

- `"Esta fase não tem solução."`
- `"A fase já está resolvida."`

---

## `POST /api/resolver` (F3)

Devolve a solução com menos cliques.

**Requisição:** `{ "fase": Fase }`

**Resposta 200**

```json
{ "cliques": [[0, 3], [0, 4], [1, 2]], "minimo": 3 }
```

`cliques` vem ordenado por linha e coluna. Qualquer ordem resolve (ADR 0001).

**Erros 422:** `"Esta fase não tem solução."`

---

## Mapeamento para o Prolog

O Python chama **só** os predicados exportados por `fronteira.pl`. Eles
recebem e devolvem apenas listas, números, strings e átomos, que é o que o
janus converte.

| Rota | Predicado | Saída em caso de erro |
|---|---|---|
| `/api/gerar` | `fronteira:gerar(+Variante:string, +N, +Dif, -Luzes, -Carimbos)` | falha → 422. O mínimo é a própria dificuldade (garantido pelo gerador) |
| `/api/verificar` | `fronteira:verificar(+Luzes, +Carimbos, -Resultado)` | `Resultado` = `[Solucoes, Minimo]` ou `sem_solucao` |
| `/api/dica` | `fronteira:dica(+Luzes, +Carimbos, -Resultado)` | `Resultado` = `[L, C]`, `sem_solucao` ou `resolvida` |
| `/api/resolver` | `fronteira:resolver(+Luzes, +Carimbos, -Resultado)` | `Resultado` = `[Cliques, Min]` ou `sem_solucao` |

## Mock para o frontend

Enquanto o backend não fica pronto, o Elm pode usar respostas fixas. Copie os
exemplos acima para `frontend/src/Mock.elm`, ou use os JSON desta página no
`/docs` do FastAPI quando as rotas existirem com um retorno fixo.
