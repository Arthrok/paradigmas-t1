<!--
  TEMPLATE DO RELATÓRIO DE ENTREGA: Paradigmas de Programação

  Como usar:
  - Copie este arquivo para a raiz do repositório do grupo, com o nome
    RELATORIO.md, e preencha todas as seções.
  - Os textos entre <!- - e - -> (como este) são instruções. Eles não
    aparecem quando o arquivo é visualizado, mas APAGUE-OS antes de entregar.
  - Troque tudo o que estiver entre [colchetes].
  - Seja direto. Frases curtas e listas valem mais que parágrafos longos.
    Um relatório típico cabe em 4 a 8 páginas.
  - O relatório e o código são avaliados juntos. Sempre que possível,
    aponte para o código (arquivo e linha) em vez de descrevê-lo. Os
    critérios de avaliação estão em AVALIACAO.md.
  - ANTES DE ENTREGAR, rode o validador na raiz do repositório:

        uv run scripts/validar_entrega.py

    Ele confere a FORMA do relatório (comentários apagados, colchetes
    preenchidos, tabelas bem formadas, seções presentes, arquivos
    existentes), não o conteúdo. Corrija todos os ERROS apontados.
-->

# [Nome do projeto]

## 1. Identificação

<!--
  Os grupos têm de 3 a 7 pessoas (5, em média). A tabela abaixo tem 5
  linhas: adicione ou remova linhas conforme o tamanho do seu grupo, aqui e
  na seção 10. Os grupos podem misturar alunos das turmas das 14h e das 16h:
  indique a turma de CADA integrante.
-->

| Nome completo | Matrícula | Turma (14h/16h) | Usuário GitHub |
|---------------|-----------|-----------------|----------------|
| [Nome]        | [000000]  | [14h]           | [@usuario]     |
| [Nome]        | [000000]  | [16h]           | [@usuario]     |
| [Nome]        | [000000]  | [14h]           | [@usuario]     |
| [Nome]        | [000000]  | [16h]           | [@usuario]     |
| [Nome]        | [000000]  | [14h]           | [@usuario]     |

- **Nome do projeto:** [o mesmo do título acima]
- **Nome do grupo:** [um nome criativo, que não se repita na turma]
  <!--
    O nome do grupo identifica vocês nas planilhas de notas e na chamada
    para a apresentação. Não dá para validar se é único, então caprichem:
    "Grupo 3" vai colidir com o "Grupo 3" da outra turma.
  -->
- **Repositório:** [https://github.com/...]
- **Commit ou tag entregue:** [`a1b2c3d` ou `v1.0`]
  <!--
    O avaliador vai olhar exatamente esta versão. Para criar uma tag:
      git tag v1.0 && git push origin v1.0
  -->
- **Ponto de partida:** [template do Sudoku com ajustes | variante do Sudoku | outro jogo conhecido | remix original | jogo inventado]
  <!--
    Escolha UMA faixa. Ela define o ajuste de escopo da nota do grupo
    (AVALIACAO.md, seção 1.5). O professor confirma a faixa na apresentação.
  -->
- **Slides da apresentação oral:** [`docs/apresentacao.pdf` | link externo | não há]
  <!--
    No final do semestre, cada grupo faz uma apresentação oral de 15
    minutos. Slides são opcionais; se o grupo usar, coloque o arquivo no
    repositório (de preferência em PDF) e indique o caminho aqui.
  -->

## 2. Resumo

<!--
  De 3 a 5 linhas: o que o sistema faz, para quem, e qual problema o
  Prolog resolve nele. Quem ler só esta seção deve entender o projeto.
-->

[Resumo do projeto.]

![Captura de tela do sistema](docs/captura.png)
<!-- Uma ou duas capturas de tela da interface. Crie a pasta docs/ se precisar. -->

## 3. Como executar

<!--
  Teste estas instruções numa máquina "limpa" (ou peça a um colega de
  outro grupo). Se o avaliador não conseguir rodar o sistema, o resto do
  trabalho não pode ser verificado.
-->

**Requisitos**:

- Linux (Ubuntu/Debian)
- SWI-Prolog ≥ 9.2 (testado: 10.0.2)
- Node.js ≥ 20
- Python 3.13 gerenciado pelo `uv`
- `uv`
- `make`

**Instalação e execução:**

```sh
git clone https://github.com/Arthrok/paradigmas-t1.git
cd paradigmas-t1
sudo add-apt-repository ppa:swi-prolog/stable
sudo apt install swi-prolog make
curl -LsSf https://astral.sh/uv/install.sh | sh
make install
make dev
```

Abra o frontend em `http://localhost:5173` e a documentação da API em
`http://localhost:8000/docs`. Para interromper os dois servidores, use
`Ctrl+C` no terminal.

**Testes:**

```sh
make test
make lint
make build
```

**Testado em:** Linux, com Chromium. O ambiente usa SWI-Prolog ≥ 9.2,
Node.js ≥ 20, Python 3.13 e `uv`.

## 4. Arquitetura

<!--
  Um diagrama simples (pode ser em texto) mostrando as partes do sistema e
  como elas se comunicam. Diga em uma frase a responsabilidade de cada parte.
-->

```
[Elm] --HTTP/JSON--> [Python] --janus--> [Prolog]
```

| Parte  | Responsabilidade | Arquivos principais |
|--------|------------------|---------------------|
| Prolog | [...]            | [`backend/prolog/...`] |
| Elm    | [...]            | [`frontend/src/...`]   |
| Python | [só integração]  | [`backend/app/...`]    |

## 5. Parte em Prolog

### 5.1 Predicados principais

| Predicado | Local | O que faz |
|-----------|-------|-----------|
| `afeta(+Carimbos, ?Clicada, ?Afetada)` | `regras.pl:88` | Relaciona uma célula clicada às luzes afetadas pelo seu carimbo, também permitindo consultar quais cliques podem afetar uma luz |
| `apertar(+Posicao, +Fase, -NovaFase)` | `regras.pl:113` | Aplica um clique e produz a nova fase, invertendo as luzes afetadas; falha em uma trava |
| `modelo(+Fase, -Apertos)` | `solver.pl:55` | Declara as variáveis booleanas dos cliques e as restrições XOR de todas as luzes |
| `num_solucoes(+Fase, -Quantidade)` | `solver.pl:95` | Conta quantas soluções existem sem enumerar matrizes de apertos |
| `solucao(+Fase, -Cliques, -Total)` | `solver.pl:112` | Enumera soluções válidas por `labeling/1` e devolve os cliques e o total |
| `solucao_minima(+Fase, -Cliques, -Total)` | `solver.pl:125` | Obtém a solução com menor número de cliques usando `aggregate_all/3` |
| `dica(+Fase, -Resultado)` | `solver.pl:143` | Devolve uma posição da solução mínima, `resolvida` ou `sem_solucao` |
| `gerar(+Variante, +Tamanho, +Dificuldade, -Fase)` | `gerador.pl:52` | Gera uma fase que tenha exatamente a dificuldade mínima solicitada |
| `verificar(+Luzes, +Textos, -Resultado)` | `fronteira.pl:41` | Converte uma fase do formato textual em termo Prolog e calcula solução mínima e quantidade |
| `resolver(+Luzes, +Textos, -Resultado)` | `fronteira.pl:64` | Devolve à API a solução mínima no formato JSON esperado pelo Elm |

### 5.2 Conceitos do paradigma lógico utilizados

- [x] Fatos e regras como base de conhecimento: os tipos de carimbo e deslocamentos ficam em `deslocamentos/2`, em `regras.pl:52-59`
- [x] Unificação e casamento de padrões: `apertar/3` destrói ou preserva o termo `fase(Luzes, Carimbos)` em `regras.pl:113-126`
- [x] Recursão (inclusive sobre listas): as linhas e colunas das matrizes são percorridas por `nth0/3`, `maplist/2` e `findall/3`
- [x] Backtracking e múltiplas soluções: `repeat/0` testa novas fases no gerador em `gerador.pl:65-78`; `solucao/3` enumera soluções por backtracking em `solver.pl:112-122`
- [x] `findall/3`, `bagof/3`, `setof/3` ou similares: `findall/3` coleta as células afetadas em `regras.pl:116` e as posições booleanas em `solver.pl:57-74`
- [x] Corte (`!`) ou negação (`\+`), e por que foram necessários: o corte em `gerador.pl:62-68` encerra o laço na primeira fase válida; `\+` não é usado neste módulo
- [x] Programação por restrições (CLP(Boolean)): a library `clpb` declara XOR e testa consistência em `solver.pl:55-81`
- [x] Predicados de ordem superior (`maplist`, `foldl`, `include`...): `maplist/2` constrói apertos e restrições; `foldl/4` calcula o XOR; `aggregate_all/3` encontra o mínimo
- [x] Relação nos dois sentidos: `afeta/3` em `regras.pl:88-94` recebe a posição clicada ou a posição afetada, dependendo do argumento que está instanciado
- [x] `aggregate_all/3`: em `solucao_minima/3`, `solver.pl:125-132`, mantém o par com menor `T` entre todas as soluções encontradas

### 5.3 Trecho em destaque

```prolog
modelo(fase(Luzes, Carimbos), Apertos) :-
    maplist(maplist(aperto_permitido), Carimbos, Apertos),
    findall(Posicao, celula(Luzes, Posicao, _), Posicoes),
    maplist(restricao_da_luz(Luzes, Carimbos, Apertos), Posicoes).

restricao_da_luz(Luzes, Carimbos, Apertos, Posicao) :-
    celula(Luzes, Posicao, Luz),
    findall(Quem, afeta(Carimbos, Quem, Posicao), Quems),
    maplist(celula(Apertos), Quems, ApertosQueAfetam),
    foldl(xor, ApertosQueAfetam, 0, Paridade),
    sat(Paridade =:= Luz).

xor(Aperto, Acumulado, Acumulado # Aperto).
```

O trecho está em `solver.pl:55-81`. `modelo/2`
não recebe uma sequência pronta nem implementa a execução dos cliques:
ele declara o que significa uma solução. Cada posição de `Apertos` é uma
variável booleana ligada à matriz de carimbos; para uma trava,
`aperto_permitido/2` fixa seu valor em `0`.

Para cada posição do tabuleiro, `restricao_da_luz/4` usa `afeta/3` no sentido
de "quem precisa ser clicado para afetar esta luz". `afeta/3` é uma relação
nos dois sentidos: no gerador e no clique ela pode partir da posição clicada,
enquanto o solver parte da posição afetada. `findall/3` reúne essas posições
clicadas e `foldl/4` monta o XOR de seus apertos. A restrição
`sat(Paridade =:= Luz)` exige paridade ímpar quando a luz inicial está acesa
e paridade par quando está apagada.

É uma solução lógica porque o programa declara as equações booleanas e o
resolvedor `clpb` procura valores consistentes. Não há um algoritmo externo
que simule cada combinação: `solucao/3` pede o `labeling/1` das variáveis,
`num_solucoes/2` usa `sat_count/2` e `solucao_minima/3` usa
`aggregate_all/3` para comparar as soluções.

Esse mesmo modelo sustenta as três features: `verificar/3` conta soluções,
`dica/3` escolhe uma posição da solução mínima e `resolver/3` devolve os
cliques mínimos. A relação entre a entrada do gerador e o modelo também é
direta: em `gerador.pl:65-78`, o gerador parte do tabuleiro apagado, aplica
cliques com `foldl/4` e volta ao `modelo/2` do solver para conferir a
dificuldade mínima antes de aceitar a fase.

## 6. Parte em Elm

### 6.1 Modelo e mensagens

<!--
  Os tipos centrais do programa: o Model, o tipo Msg e os custom types do
  domínio. Explique as escolhas: por que um custom type e não um Bool, por
  que Maybe ou Result, etc.
-->

```elm
[type alias Model = ...]
[type Msg = ...]
```

[Explicação das escolhas.]

### 6.2 Conceitos do paradigma funcional utilizados

- [ ] Arquitetura Elm (Model, update, view): [onde]
- [ ] Custom types e `case` exaustivo: [onde]
- [ ] `Maybe` e `Result` no lugar de null e exceções: [onde]
- [ ] Funções de ordem superior e aplicação parcial: [onde]
- [ ] Composição (`|>`, `>>`): [onde]
- [ ] Decoders e encoders JSON: [onde]
- [ ] Comandos e subscriptions (efeitos controlados): [onde]
- [ ] Imutabilidade e atualização de records: [onde]
- [ ] Outro: [...]

### 6.3 Trecho em destaque

```elm
[trecho]
```

[Explicação.]

## 7. Integração

<!--
  Curto: a parte Python não é avaliada. Liste as rotas ou a forma de
  comunicação e o formato dos dados trocados. Se o grupo não usou Python,
  explique como Elm e Prolog se comunicam.
-->

| Rota / chamada | Entrada | Saída | Predicado Prolog |
|----------------|---------|-------|------------------|
| [`POST /api/...`] | [...] | [...] | [`...`] |

## 8. Testes e validação

O projeto usa três níveis de testes automáticos:

- **PLUnit** em `backend/prolog/test_*.pl`: regras dos carimbos, bordas,
  resoluções, geração e fronteira com o Python.
- **pytest** em `backend/tests/test_api.py`: contrato HTTP, formatos JSON,
  códigos de status e mensagens de regra de negócio.
- **elm-test** em `frontend/tests/*.elm`: domínio Elm, decoders/encoders,
  estados da interface e casos de resposta da API.

Executar todos os testes e verificações locais:

```sh
make test
make lint
make build
```

### Casos de borda

| Caso de borda | Comportamento esperado | Evidência automática |
|---|---|---|
| Dica em fase resolvida | 422 com `"A fase já está resolvida."` | pytest `test_dica_em_fase_resolvida`; elm-test em `ApiTest` e `MainTest` |
| Fase sem solução | 200 com `solucoes: 0` ao verificar; dica e resolução retornam 422 com `"Esta fase não tem solução."` | pytest `test_verificar_sem_solucao_nao_e_erro`, `test_dica_sem_solucao` e `test_resolver_sem_solucao`; elm-test em `MainTest` |
| Dificuldade impossível | 422 com `"Não foi possível gerar uma fase com essa dificuldade."` | pytest `test_gerar_dificuldade_impossivel`; PLUnit em `test_gerador.pl` |
| Tamanho inválido | rejeita tamanhos fora de 4–6 e matrizes não NxN | pytest `test_gerar_rejeita_tamanho_fora_da_faixa` e `test_verificar_rejeita_matriz_nao_quadrada`; elm-test em `FaseTest` e `EditorTest` |
| Carimbo inválido | rejeita nome fora das formas conhecidas | pytest `test_verificar_rejeita_carimbo_desconhecido`; elm-test em `ApiTest` |
| Backend fora do ar ou inacessível | Elm transforma falha de rede/timeout em uma mensagem de erro, sem considerar resposta como sucesso | elm-test em `ApiTest` (`backend fora do ar` e `timeout`) |

No Linux, o roteiro manual ponta a ponta consiste em iniciar `make dev`,
gerar uma fase em cada variante, pedir uma dica, verificar que a dica deixa o
tabuleiro válido, seguir a solução até a vitória e repetir o fluxo no editor.
O resultado deve coincidir com as rotas documentadas em `docs/api.md`.

## 9. Limitações e problemas conhecidos

<!--
  Seja honesto. Um problema conhecido e bem descrito vale mais que um
  problema escondido que o avaliador descobre sozinho.
-->

- [Limitação ou bug conhecido, e em que situação acontece.]
- [O que o grupo faria com mais tempo.]

## 10. Contribuição de cada integrante

<!--
  O que cada pessoa fez. Deve ser coerente com o histórico de commits do
  repositório. Todos os integrantes precisam concordar com esta tabela.
-->

| Integrante | Principais contribuições |
|------------|--------------------------|
| [Nome]     | [...] |
| [Nome]     | [...] |
| [Nome]     | [...] |
| [Nome]     | [...] |
| [Nome]     | [...] |

<!--
  Além desta tabela, que é do grupo, cada integrante entrega uma avaliação
  360 graus individual no SEU repositório do GitHub Classroom, em
  avaliacao-360/<matricula>.md. Veja o modelo em avaliacao-360/TEMPLATE.md.
-->

## 11. Fontes, código de terceiros e uso de IA

<!--
  Declare tudo o que não foi escrito pelo grupo. Declarar não tira pontos;
  deixar de declarar pode anular o trabalho.
-->

**Código reaproveitado.** [Ex.: "Partimos do template do Sudoku. Mantivemos
a integração Python e a estrutura do frontend; o arquivo `x.pl` e os
módulos `Y.elm` e `Z.elm` foram escritos pelo grupo."]

**Referências.** [Livros, documentação, tutoriais, repositórios consultados.]

**Uso de ferramentas de IA.**

- **Faixa de uso no código:** [nenhum | pontual | auxiliar | intensivo]
  <!--
    nenhum: não usou. pontual: autocompletar, dúvidas, explicar erros.
    auxiliar: trechos gerados pela IA e revisados pelo grupo. intensivo: a
    IA escreveu a maior parte do código. Veja o efeito em AVALIACAO.md,
    seção 1.5. Não declarar anula o trabalho; declarar não tira pontos.
  -->

| Ferramenta | Para que foi usada | Como o grupo verificou o resultado |
|------------|--------------------|------------------------------------|
| [Nome ou "nenhuma"] | [...] | [...] |

## 12. Apresentação oral

<!--
  A apresentação tem 15 minutos e acontece no final do semestre. Uma
  divisão que costuma funcionar: 2 min de contexto, 5 min de demonstração
  do sistema funcionando, 6 min mostrando o código Prolog e Elm mais
  interessante, 2 min de limitações e aprendizados. Todos os integrantes
  devem falar.

  Preencha esta seção antes da apresentação.
-->

- **Slides:** [mesmo caminho indicado na seção 1, ou "não há"]
- **Roteiro:**

| Parte | Duração | Quem apresenta |
|-------|:-------:|----------------|
| [Contexto e objetivo] | [2 min] | [Nome] |
| [Demonstração] | [5 min] | [Nome] |
| [Código Prolog] | [3 min] | [Nome] |
| [Código Elm] | [3 min] | [Nome] |
| [Limitações e aprendizados] | [2 min] | [Nome] |

## 13. Reflexão sobre os paradigmas

<!--
  De 1 a 3 parágrafos. Perguntas que podem ajudar:
  - O que ficou mais simples em Prolog do que seria numa linguagem
    imperativa? E o que ficou mais difícil?
  - O que o compilador do Elm impediu que desse errado?
  - Como a forma de pensar mudou entre as duas linguagens?
-->

[Reflexão.]

---

<!--
  CHECKLIST ANTES DE ENTREGAR (apague esta seção depois de conferir)

  - [ ] `uv run scripts/validar_entrega.py` termina sem erros.
  - [ ] Todos os integrantes, com matrícula e turma, estão na seção 1.
  - [ ] O commit ou tag da seção 1 existe no repositório e é a versão final.
  - [ ] As instruções da seção 3 funcionam numa máquina sem nada instalado
        além dos requisitos listados.
  - [ ] Os locais indicados (arquivo:linha) conferem com o commit entregue.
  - [ ] As seções 10 e 11 foram revisadas por todo o grupo.
  - [ ] Se há slides, o arquivo está no repositório e o caminho da seção 1
        está certo.
  - [ ] Cada integrante entregou a própria avaliação 360 graus no seu
        repositório individual, em avaliacao-360/<matricula>.md.
  - [ ] Nenhum texto entre [colchetes] ou comentário de instrução sobrou.
-->
