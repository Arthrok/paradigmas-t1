# ADR 0004: Modelar o jogo com restrições booleanas (`clpb`)

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

Pelas propriedades do ADR 0001 (ordem não importa, clicar 2x = não clicar),
uma solução é uma matriz `A` de variáveis 0/1 ("aperto essa célula?"). Para
cada luz `L`:

```
luz_inicial(L)  XOR  ( XOR de A[c] para toda célula c cujo carimbo afeta L )  =  0
```

Células travadas têm `A[c] = 0`.

## Decisão

1. Declarar essas equações com **`library(clpb)`** do SWI-Prolog, usando
   `sat(Expr =:= 0)` com `#` (XOR).
2. **F1 (verificar solução):** a fase não tem solução ⇔ postar as restrições
   falha. O número de soluções vem de `sat_count/2`, sem enumerar.
3. **F3 (solução mínima):** enumerar as soluções com `labeling/1` e pegar a de
   menor soma com `aggregate_all(min(...))`. Na validação, cada fase teve no
   máximo 4 soluções.
4. **F2 (dica):** resolver o estado *atual* e devolver qualquer célula da
   solução mínima. Como a ordem não importa, qualquer uma serve.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Força bruta (2^25 ≈ 33 milhões de combinações no 5x5) | Inviável, e é justamente o "como" que o paradigma lógico evita |
| `clpfd` com `mod 2` | Funciona, mas propaga mal a paridade, e XOR é nativo em `clpb` |
| Eliminação gaussiana em GF(2) escrita à mão | Rápida, mas é um algoritmo imperativo traduzido para Prolog (nível 2 da rubrica) |
| `weighted_maximum/3` da `clpb` para o mínimo | Testado: ficou lento demais (timeout acima de 120 s no 5x5) |

## Consequências

- Um único modelo (`modelo/3`) sustenta F1, F2, F3 e F4.
- O código descreve *o que é* uma solução, que é o argumento central da
  seção 5.3 do relatório.
- O custo é ~0,1–0,4 s por chamada no 5x5, dominado pela montagem das
  restrições. A UI precisa de estado de carregamento.
- Limite de tamanho suportado: 4x4 a 7x7 (validado de 5x5 a 7x7).
