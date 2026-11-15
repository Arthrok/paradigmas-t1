"""Testes da API HTTP (pytest).

O TestClient do FastAPI chama a aplicação diretamente, sem subir servidor.
As regras do jogo são testadas em Prolog (backend/prolog/test_*.pl); aqui
conferimos só a "cola": rotas, formato do JSON e códigos de status.

Rodar: `make test-backend` (na raiz) ou `uv run pytest` (em backend/).
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_aplicacao_sobe_com_o_prolog_carregado():
    response = client.get("/openapi.json")
    assert response.status_code == 200
