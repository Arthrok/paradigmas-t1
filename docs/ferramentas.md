# Ferramentas e ambiente

## Versões

| Ferramenta | Versão | Para quê | Como instalar |
|---|---|---|---|
| SWI-Prolog | **≥ 9.2** (testado: 10.0.2) | lógica do jogo | Ubuntu: `sudo add-apt-repository ppa:swi-prolog/stable && sudo apt install swi-prolog` |
| Node.js | **20 ou mais** | Vite, compilador Elm | `nvm install 20 && nvm use 20` |
| uv | qualquer recente | Python do backend | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Elm | 0.19.1 | frontend | já vem pelo `npm install` (em `frontend/node_modules`) |
| elm-format | 0.8.x | formatação (é medida) | já vem pelo `npm install` |
| elm-test | 0.19.x | testes do Elm | já vem pelo `npm install` (a issue de setup adiciona) |
| make | qualquer | atalhos | já vem no Linux; no Windows use WSL |

> O `npm install` instala o Elm localmente, então **não** precisa de
> `npm install -g elm`.

Confira o ambiente:

```sh
swipl --version     # >= 9.2
node --version      # >= v20
uv --version
```

## Comandos do dia a dia

| Comando | O que faz |
|---|---|
| `make install` | instala as dependências do backend e do frontend (uma vez) |
| `make dev` | sobe backend (:8000) e frontend (:5173) com recarga automática |
| `make test` | todos os testes: plunit, pytest e elm-test |
| `make test-prolog` | só os testes plunit |
| `make test-backend` | só o pytest |
| `make test-elm` | só o elm-test |
| `make format` | aplica o `elm-format` em `frontend/src` e `frontend/tests` |
| `make validar` | roda o validador do relatório do professor |

Abra <http://localhost:5173> para jogar e <http://localhost:8000/docs> para
testar as rotas da API na mão.

## Desenvolvendo o Prolog sem o resto do sistema

É o jeito mais rápido de trabalhar na lógica:

```sh
swipl backend/prolog/solver.pl
?- Fase = fase([[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]],
               [[cruz,cruz,cruz,cruz,cruz],[cruz,cruz,cruz,cruz,cruz],[cruz,cruz,cruz,cruz,cruz],
                [cruz,cruz,cruz,cruz,cruz],[cruz,cruz,cruz,cruz,cruz]]),
   num_solucoes(Fase, N), solucao_minima(Fase, Cliques, K).
% N = 4, K = 11
```

Só ligue o predicado ao Python depois que ele funcionar no `swipl`.

## Editor (VS Code)

| Extensão | Para quê |
|---|---|
| `elm-tooling.elm-ls-vscode` | erros do Elm no editor e formatação ao salvar |
| `arthurwang.vsc-prolog` (ou similar) | realce de sintaxe Prolog |
| `bierner.markdown-mermaid` | ver os diagramas destes docs no preview |

Ative **Format on Save** para arquivos `.elm`.

## Problemas comuns

- **`ImportError: libswipl.so...`** ao subir o backend: o `janus-swi` foi
  compilado contra outra versão do SWI-Prolog. Rode
  `cd backend && uv sync --reinstall-package janus-swi --no-binary-package janus-swi --no-cache`.
- **Vite reclama da versão do Node:** você está no Node 18. Rode `nvm use 20`.
