# ADR 0005: Representação da fase

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

A fase precisa trafegar entre Elm, Python e Prolog. O janus converte listas e
strings do Python em listas e strings do Prolog, mas **não** converte termos
compostos, e strings chegam como strings, não como átomos.

## Decisão

Uma fase é um objeto com **duas matrizes NxN**:

```json
{
  "luzes":    [[0, 1, 0], [1, 1, 0], [0, 0, 1]],
  "carimbos": [["cruz", "xis", "trava"], ["linha", "bloco", "cruz"], ["coluna", "cruz", "xis"]]
}
```

- `luzes[i][j]` ∈ {0, 1}, onde 1 = acesa;
- `carimbos[i][j]` ∈ {`cruz`, `xis`, `linha`, `coluna`, `bloco`, `trava`};
- **a trava é um tipo de célula**, não uma terceira matriz. Na validação
  usamos uma matriz separada, e a semântica é a mesma.
- Posições são `[linha, coluna]`, com índice a partir de 0.

Em cada camada:

| Camada | Representação |
|---|---|
| JSON / Python | as duas matrizes acima |
| Prolog | `fase(Luzes, Carimbos)`, com carimbos como **átomos**. A conversão string → átomo acontece só no módulo `fronteira.pl` |
| Elm | tipo opaco `Fase`, com `Celula = Ativa Forma Luz \| Travada Luz` e `Luz = Acesa \| Apagada` |

## Consequências

- No Elm, "célula travada com carimbo" é **impossível de representar**
  (critério 3 da rubrica).
- O decoder do Elm junta as duas matrizes numa só, o que é um bom exemplo de
  decoder próprio.
- A validação de forma (matrizes quadradas, tamanhos iguais) acontece no
  pydantic e no `Fase.criar` do Elm. A validação de domínio (nome de carimbo)
  acontece no Prolog, com `must_be/2`.
