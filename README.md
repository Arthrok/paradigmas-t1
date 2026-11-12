# Carimbó

> Nome provisório. Trabalho final de Paradigmas de Programação: lógica em
> **Prolog**, interface em **Elm**.

Um quebra-cabeça de apagar luzes com duas regras próprias:

- **Carimbos:** cada célula tem o seu próprio desenho de efeito (cruz, xis,
  linha, coluna, bloco). Clicar inverte as células cobertas pelo desenho.
- **Células travadas:** não podem ser clicadas, mas são afetadas pelas vizinhas.

O objetivo é apagar todas as luzes. O Prolog modela o jogo como um sistema de
restrições booleanas e entrega cinco features:

| # | Feature | O que faz |
|---|---|---|
| F1 | Verificar solução | diz se uma fase tem solução e quantas |
| F2 | Dica | sugere um próximo clique correto a partir de qualquer estado |
| F3 | Solução mínima | acha a solução com menos cliques |
| F4 | Gerador | cria fases com solução garantida e dificuldade exata |
| F5 | Variantes | clássico, carimbos, carimbos + travas |

## Documentação

| Documento | Conteúdo |
|---|---|
| [Arquitetura](docs/arquitetura.md) | camadas, diagramas, fluxos, estrutura de pastas |
| [Contrato da API](docs/api.md) | rotas, JSON, erros; permite trabalhar em paralelo |
| [Design do Prolog](docs/design-prolog.md) | módulos, predicados, modelo de restrições, testes |
| [Design do Elm](docs/design-elm.md) | tipos, módulos, máquina de estados, telas, testes |
| [ADRs](docs/adr/README.md) | decisões e por quê |
| [Ferramentas](docs/ferramentas.md) | versões, instalação, comandos |
| [Como contribuir](docs/contribuindo.md) | branches, commits, PR, definição de pronto |
| [Plano de issues](docs/plano-de-issues.md) | divisão, dependências, cronograma |
| [Validação](docs/validacao/README.md) | protótipo que provou que a regra funciona |

## Integrantes

| Nome                             | GitHub                                                                     | Matrícula |
| -------------------------------- | -------------------------------------------------------------------------- | --------- |
| Arthur Alves Melo                | [@arthrok](https://github.com/arthrok)                                     | 222037657 |
| Bruna de Lima Santos             | [@libruna](https://github.com/libruna)                                     | 211041105 |
| Caio Lucas Lelis Borges          | [@caio-lelis](https://github.com/caio-lelis)                               | 211062900 |
| Isaque Santos                    | [@IsaqueSH](https://github.com/IsaqueSH)                                   | 211061903 |
| João Pedro da Silva Rodrigues    | [@joaopedrodasilvarodrigues](https://github.com/joaopedrodasilvarodrigues) | 211031074 |
| Maria Eduarda dos Santos Marques | [@EduardaSMarques](https://github.com/EduardaSMarques)                     | 200023985 |

## Origem

Estrutura baseada no template do professor:
<https://github.com/fabiommendes/paradigmas-trabalho-final>
(ver [ADR 0002](docs/adr/0002-base-no-template.md)).
