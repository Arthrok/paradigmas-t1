# Atalhos para as tarefas mais comuns. Uso: `make <alvo>`.
#
# O `make` só interpreta as linhas de receita (indentadas com TAB), cada uma
# executada num shell separado; por isso usamos `cd pasta && comando`.

PROLOG_FONTES := $(filter-out $(wildcard backend/prolog/test_*.pl),$(wildcard backend/prolog/*.pl))
PROLOG_TESTES := $(wildcard backend/prolog/test_*.pl)

.PHONY: install dev backend frontend build test test-prolog test-backend lint lint-prolog lint-elm format validar

install:            ## instala as dependências do backend e do frontend
	cd backend && uv sync
	cd frontend && npm install

dev:                ## sobe backend e frontend juntos (Ctrl+C encerra ambos)
	$(MAKE) -j2 backend frontend

backend:            ## só o backend: http://localhost:8000/docs
	cd backend && uv run fastapi dev app/main.py

frontend:           ## só o frontend: http://localhost:5173
	cd frontend && npm run dev

build:              ## compila o frontend (falha se o Elm não compilar)
	cd frontend && npm run build

test: test-prolog test-backend

test-prolog:        ## testes plunit
	swipl -g run_tests -t halt $(PROLOG_TESTES)

test-backend:       ## testes da API (pytest)
	cd backend && uv run pytest

lint: lint-prolog lint-elm

lint-prolog:        ## falha se algum arquivo .pl carregar com aviso
	swipl --on-warning=status --on-error=status -g halt $(PROLOG_FONTES) $(PROLOG_TESTES)

lint-elm:           ## falha se algum arquivo .elm não estiver formatado
	cd frontend && npm run lint

format:             ## formata o código Elm
	cd frontend && npm run format

validar:            ## confere a forma do RELATORIO.md e das avaliações 360
	uv run scripts/validar_entrega.py
