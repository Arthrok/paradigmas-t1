# Plano de issues

Prazo sem desconto: **18/11/2026, 23h59**. As issues estão no GitHub; este
documento mostra o panorama, as dependências e a ordem.

## Equipe e frentes

| Pessoa | GitHub | Frente principal |
|---|---|---|
| Arthur Alves Melo | @Arthrok | infra, Python, fronteira Prolog, integração, entrega |
| Caio Lucas Lelis Borges | @caio-lelis | Prolog: regras e gerador · editor de fases (Elm) |
| Isaque Santos | @IsaqueSH | Prolog: solver, dica, solução mínima · testes de borda |
| Maria Eduarda dos Santos Marques | @EduardaSMarques | Elm: domínio (`Fase`, `Historico`) e testes |
| João Pedro da Silva Rodrigues | @joaopedrodasilvarodrigues | Elm: `Api`, `Main`, tela de nova fase |
| Bruna de Lima Santos | @libruna | Elm: view do tabuleiro, visual, dica e solução na UI |

A divisão é uma sugestão: troquem à vontade, mas atualizem os responsáveis na
issue. **Todo mundo precisa conseguir explicar o código atribuído a si**
(seção 2.1 da avaliação), e todo mundo tem uma parte do relatório.

## As 5 features e onde cada uma aparece

| Feature | Prolog | UI |
|---|---|---|
| **F1** Verificar solução | #5 | #20 |
| **F2** Dica | #6 | #17 |
| **F3** Solução mínima | #6 | #18 |
| **F4** Gerador | #7 | #16 |
| **F5** Variantes | #7 | #16 |

## Lista de issues

### Onda 0: fundação (11–12/11)

| # | Issue | Responsável | Depende de |
|---|---|---|---|
| 1 | Trazer o template do professor e adaptar ao projeto | Arthur | — |
| 2 | Revisar e aprovar a documentação, os ADRs e o contrato da API | todos | — |
| 3 | CI no GitHub Actions (testes, elm-format, swipl sem avisos) | Arthur | 1 |

### Onda 1: núcleo em paralelo (13–15/11)

| # | Issue | Responsável | Depende de |
|---|---|---|---|
| 4 | `regras.pl`: carimbos, `afeta/4`, `apertar/3`, `resolvida/1` | Caio | 1 |
| 5 | `solver.pl`: modelo de restrições e **F1** verificar solução | Isaque | 1, 4* |
| 6 | `solver.pl`: **F3** solução mínima e **F2** dica | Isaque | 5 |
| 7 | `gerador.pl`: **F4** gerador e **F5** variantes | Caio | 4, 6 |
| 8 | `fronteira.pl`: API pública do Prolog para o Python | Arthur | 5, 6, 7 |
| 9 | Rotas FastAPI e testes pytest | Arthur | 1, 8* |
| 10 | `Fase.elm`: tipos do domínio, `apertar`, `resolvida`, `criar` | Maria Eduarda | 1 |
| 11 | `Historico.elm`: desfazer/refazer genérico + testes | Maria Eduarda | 1 |
| 12 | Testes fuzz de `Fase.elm` | Maria Eduarda | 10 |
| 13 | `Api.elm`: requisições, encoders, decoders, `Remoto` | João Pedro | 10 |
| 14 | `View/Tabuleiro.elm`: grid, ícones dos carimbos, visual | Bruna | 10 |
| 15 | `Main.elm`: Model, Msg, máquina de estados, clique local | João Pedro | 10, 11, 13, 14 |

\* Dá para começar antes usando o contrato ([`api.md`](api.md),
[`design-prolog.md`](design-prolog.md)) com stub ou mock, e integrar quando a
dependência fechar.

### Onda 2: features na UI (15–16/11)

| # | Issue | Responsável | Depende de |
|---|---|---|---|
| 16 | **F4 + F5** na UI: tela de nova fase (tamanho, nível, variante) | João Pedro | 9, 15 |
| 17 | **F2** na UI: pedir dica e destacar a célula | Bruna | 9, 15 |
| 18 | **F3** na UI: mínimo, animação da solução, tela de vitória | Bruna | 9, 15 |
| 19 | Desfazer, refazer e reiniciar na UI | Maria Eduarda | 11, 15 |
| 20 | **F1** na UI: editor de fases com verificação | Caio | 9, 15 |
| 21 | Integração ponta a ponta e casos de borda (seção 8 do relatório) | Arthur, Isaque | 16, 17, 18 |

### Onda 3: entrega (16–18/11)

| # | Issue | Responsável | Depende de |
|---|---|---|---|
| 22 | Relatório: seções 1–4 e 7 | Arthur | 21 |
| 23 | Relatório: seção 5 (Prolog) | Caio, Isaque | 7, 8 |
| 24 | Relatório: seção 6 (Elm) | Maria Eduarda, João Pedro, Bruna | 16–19 |
| 25 | Relatório: seções 8–13 (coletivas) | todos | 21 |
| 26 | Apresentação: roteiro de 15 min e ensaio | todos | 21 |
| 27 | Entrega: validador, repositório do Classroom, versão final | Arthur | 22–26 |

## Grafo de dependências

```mermaid
flowchart LR
    classDef o0 fill:#e0e7ff,stroke:#4f46e5,color:#1e1b4b
    classDef pl fill:#fef3c7,stroke:#d97706,color:#451a03
    classDef el fill:#dcfce7,stroke:#16a34a,color:#052e16
    classDef py fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef ft fill:#fce7f3,stroke:#db2777,color:#500724
    classDef en fill:#e0f2fe,stroke:#0284c7,color:#082f49

    I1["#1 template"]:::o0
    I2["#2 revisar docs"]:::o0
    I3["#3 CI"]:::o0

    I4["#4 regras.pl"]:::pl
    I5["#5 solver F1"]:::pl
    I6["#6 F3 + F2"]:::pl
    I7["#7 gerador F4 F5"]:::pl
    I8["#8 fronteira.pl"]:::pl
    I9["#9 rotas FastAPI"]:::py

    I10["#10 Fase.elm"]:::el
    I11["#11 Historico.elm"]:::el
    I12["#12 fuzz Fase"]:::el
    I13["#13 Api.elm"]:::el
    I14["#14 View Tabuleiro"]:::el
    I15["#15 Main.elm"]:::el

    I16["#16 UI F4 F5"]:::ft
    I17["#17 UI F2"]:::ft
    I18["#18 UI F3"]:::ft
    I19["#19 desfazer"]:::ft
    I20["#20 UI F1 editor"]:::ft
    I21["#21 ponta a ponta"]:::ft

    I22["#22 rel. 1-4, 7"]:::en
    I23["#23 rel. Prolog"]:::en
    I24["#24 rel. Elm"]:::en
    I25["#25 rel. 8-13"]:::en
    I26["#26 apresentação"]:::en
    I27["#27 entrega"]:::en

    I1 --> I3
    I1 --> I4 --> I5 --> I6 --> I7
    I4 --> I7
    I5 & I6 & I7 --> I8 --> I9
    I1 --> I9
    I1 --> I10 --> I12
    I1 --> I11
    I10 --> I13 & I14
    I10 & I11 & I13 & I14 --> I15
    I9 & I15 --> I16 & I17 & I18 & I20
    I11 & I15 --> I19
    I16 & I17 & I18 --> I21
    I21 --> I22 & I25 & I26
    I7 & I8 --> I23
    I16 & I17 & I18 & I19 --> I24
    I22 & I23 & I24 & I25 & I26 --> I27
```

**Caminho crítico:** #1 → #4 → #5 → #6 → #7 → #8 → #9 → #16 → #21 → #27.
O Prolog é o gargalo, então ele começa primeiro e não pode atrasar.
Enquanto isso, o Elm avança com mock (#10–#15 não dependem do backend).

## Cronograma

```mermaid
gantt
    title Carimbó, plano até a entrega
    dateFormat YYYY-MM-DD
    axisFormat %d/%m

    section Onda 0
    Template (#1)                 :o1, 2026-11-11, 1d
    Revisar docs (#2)             :o2, 2026-11-11, 2d
    CI (#3)                       :o3, after o1, 1d

    section Prolog
    regras.pl (#4)                :p4, 2026-11-12, 1d
    solver F1 (#5)                :p5, 2026-11-13, 1d
    F3 + F2 (#6)                  :p6, after p5, 1d
    gerador F4 F5 (#7)            :p7, after p6, 1d
    fronteira (#8)                :p8, after p7, 1d

    section Python
    rotas + pytest (#9)           :b9, 2026-11-13, 3d

    section Elm
    Fase.elm (#10)                :e10, 2026-11-12, 2d
    Historico (#11)               :e11, 2026-11-12, 1d
    fuzz (#12)                    :e12, after e10, 1d
    Api.elm (#13)                 :e13, after e10, 2d
    View Tabuleiro (#14)          :e14, after e10, 2d
    Main.elm (#15)                :e15, 2026-11-14, 2d

    section Features
    UI F4 F5 (#16)                :f16, 2026-11-15, 2d
    UI F2 (#17)                   :f17, 2026-11-15, 1d
    UI F3 (#18)                   :f18, 2026-11-15, 2d
    desfazer (#19)                :f19, 2026-11-15, 1d
    UI F1 editor (#20)            :f20, 2026-11-16, 1d
    ponta a ponta (#21)           :f21, 2026-11-16, 2d

    section Entrega
    relatório (#22-#25)           :r, 2026-11-16, 3d
    apresentação (#26)            :a, 2026-11-17, 2d
    entrega final (#27)           :crit, milestone, 2026-11-18, 0d
```

## Etiquetas e marcos no GitHub

- **Marcos:** `Onda 0: fundação` (12/11), `Onda 1: núcleo` (15/11),
  `Onda 2: features` (16/11), `Onda 3: entrega` (18/11).
- **Etiquetas de área:** `prolog`, `elm`, `backend`, `infra`, `docs`,
  `relatório`, `entrega`.
- **Etiquetas de feature:** `F1-verificar`, `F2-dica`, `F3-minima`,
  `F4-gerador`, `F5-variantes`.
- **Outras:** `extra` (dá para cortar se o prazo apertar: #20, a animação
  de #18).
