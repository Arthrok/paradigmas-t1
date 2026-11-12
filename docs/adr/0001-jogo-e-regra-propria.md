# ADR 0001: Jogo escolhido e regra própria (carimbos + células travadas)

- **Status:** aceita
- **Data:** 2026-11-11

## Contexto

O trabalho pede um jogo com a lógica em Prolog e a interface em Elm. A rubrica
(`AVALIACAO.md` do template do professor) valoriza:

- um Prolog que resolve algo que pede busca, restrições ou base de
  conhecimento, e não um `if` disfarçado (critério 2);
- algo não trivial: múltiplas soluções, geração, explicação (nível 4);
- um ajuste de escopo Δ: jogo conhecido vale 0, *remix com regra própria*
  vale +0,5 e jogo inventado vale +1,0.

O prazo sem desconto é 18/11/2026, uma semana a partir desta decisão.

## Decisão

Fazer um **quebra-cabeça de apagar luzes** (mecânica do clássico "Lights Out")
com duas regras próprias:

1. **Carimbos:** cada célula tem o seu próprio desenho de efeito. Clicar nela
   inverte as células cobertas pelo desenho, e não só a cruz clássica.
2. **Células travadas:** algumas células não podem ser clicadas, mas
   continuam sendo invertidas pelas vizinhas.

| Carimbo  | Efeito (`#` = inverte, `●` = célula clicada) |
|----------|-----------------------------------------------|
| `cruz`   | a própria célula e as 4 vizinhas ortogonais |
| `xis`    | a própria célula e as 4 vizinhas diagonais |
| `linha`  | a própria célula e 2 para cada lado, na horizontal |
| `coluna` | a própria célula e 2 para cima e para baixo |
| `bloco`  | o quadrado 3x3 centrado na célula |
| `trava`  | não pode ser clicada (não tem efeito próprio) |

```
cruz        xis         linha           coluna   bloco
. # .       # . #                       #        # # #
# ● #       . ● .       # # ● # #       #        # ● #
. # .       # . #                       ●        # # #
                                        #
                                        #
```

Nome provisório do jogo: **Carimbó**.

### As 5 features que o Prolog entrega

| #  | Feature | O que faz |
|----|---------|-----------|
| F1 | **Verificar solução** | Diz se uma fase tem solução e quantas |
| F2 | **Dica** | Sugere um próximo clique correto a partir do estado *atual* |
| F3 | **Solução mínima** | Acha a solução com menos cliques |
| F4 | **Gerador** | Cria fases que com certeza têm solução, com dificuldade exata (= mínimo de cliques) |
| F5 | **Variantes** | `classico` (só cruz), `carimbos`, `carimbos_travas`, sem reescrever F1–F4 |

## Por que essas regras e não outras

As 5 features dependem de duas propriedades do jogo:

1. **A ordem dos cliques não importa.**
2. **Clicar duas vezes é o mesmo que não clicar.**

Com elas, uma solução é só um *conjunto* de células, e cada célula vira uma
variável booleana. O jogo vira um sistema de restrições XOR (ver ADR 0004).
Carimbos e travas **preservam** as duas propriedades: carimbo só muda
*quem afeta quem*, e trava só fixa uma variável em 0. Por isso as 5 features
continuam valendo sem reescrita.

Regras que quebrariam o modelo, e por isso foram descartadas:

- **reação em cadeia** (uma luz que acende dispara outra): a ordem passa a importar;
- **duelo com pontuação por turno**: troca restrições por busca adversarial,
  que é cara demais em 5x5 para o prazo;
- **luzes de 3 cores**: já é uma variante conhecida, então não conta como regra própria.

## Validação feita antes da decisão

Um protótipo descartável (em [`docs/validacao/`](../validacao/)) foi
executado no SWI-Prolog 10.0.2:

| Teste | Resultado |
|---|---|
| Regressão: modo clássico 5x5, só o centro aceso | 4 soluções e mínimo 11 (valores conhecidos) |
| Solução do Prolog aplicada por um simulador independente apaga tudo | 60/60 fases |
| Seguir a dica diminui o mínimo em exatamente 1 | 60/60 fases |
| O gerador acerta a dificuldade pedida | 60/60 (5x5, 6x6, 7x7; dificuldades 3 a 20) |
| Tempo do gerador | típico 0,02–0,3 s; pior caso 1,8 s (5x5 sem travas, dificuldade 15) |
| Soluções por fase | no máximo 4, então enumerar para achar o mínimo é barato |
| Fases com luzes sorteadas ao acaso | só 10–40% têm solução, então o gerador é obrigatório |

## Consequências

- O Prolog faz trabalho de verdade: as 5 features vêm de um único modelo.
- O Elm ganha tipos naturais (`Forma`, `Celula = Ativa ... | Travada ...`).
- Pedimos Δ = +0,5 (remix). Quem confirma a faixa é o professor, na
  apresentação, e este ADR é a justificativa.
- Risco: o professor pode classificar como "jogo conhecido" (Δ = 0). Isso não
  traz prejuízo além de perder o bônus.
