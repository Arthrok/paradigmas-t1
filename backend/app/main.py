"""API HTTP do Carimbó.

Esta camada é só "cola": recebe JSON, valida o formato com Pydantic, chama o
Prolog (via app/prolog.py) e devolve JSON. Nenhuma regra do jogo mora aqui.
O contrato das rotas está em docs/api.md.

Rodar em modo de desenvolvimento (recarrega ao salvar):
    uv run fastapi dev app/main.py

Documentação interativa: http://localhost:8000/docs
"""

from fastapi import FastAPI

from app import prolog  # noqa: F401  (carrega o Prolog ao subir o servidor)

app = FastAPI(title="Carimbó (Prolog + Elm)")
