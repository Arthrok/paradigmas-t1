# ADR 0007: Gerador por cliques reversos e dificuldade verificada

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

Sortear luzes ao acaso gera fases sem solução em 60–90% dos casos (ADR 0001).
Também queremos que a "dificuldade" signifique algo mensurável.

## Decisão

**Dificuldade = número mínimo de cliques para resolver a fase.**

Algoritmo de `gerar(+Variante, +N, +Dificuldade, -Fase)`:

1. Sortear o layout de carimbos conforme a variante (ex.: 15% de travas em
   `carimbos_travas`).
2. Partir do tabuleiro **apagado** e aplicar `Dificuldade` cliques distintos
   em células não travadas, sorteadas. Como dá para desfazer cada clique, a
   fase **sempre tem solução**.
3. Calcular a solução mínima (F3). Se ela for **menor** que a dificuldade
   (porque os cliques sorteados tinham um atalho), descartar e tentar de novo
   (`repeat`).
4. **Limite de tentativas** (ex.: 200). Se estourar, falhar, e a API responde
   422. Isso é necessário porque algumas dificuldades são inalcançáveis: no
   5x5 clássico, o mínimo nunca passa de 15.

## Consequências

- Fase gerada = fase com solução **e** com dificuldade exata. Validado em
  60/60 casos.
- A UI pode mostrar "mínimo: K" sem uma chamada extra (vem na resposta de
  `/api/gerar`).
- As variantes (F5) mudam só o passo 1.
