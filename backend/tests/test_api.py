"""Testes da API HTTP (pytest).

O TestClient do FastAPI chama a aplicação diretamente, sem subir servidor.
As regras do jogo são testadas em Prolog (backend/prolog/test_*.pl); aqui
conferimos só a "cola": rotas, formato do JSON e códigos de status.

Rodar: `make test-backend` (na raiz) ou `uv run pytest` (em backend/).
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

SO_CRUZ = [["cruz"] * 5 for _ in range(5)]
APAGADO = [[0] * 5 for _ in range(5)]


def com_luzes_acesas(*posicoes: tuple[int, int]) -> dict:
    """Uma fase clássica 5x5 com as luzes das posições acesas."""
    luzes = [linha[:] for linha in APAGADO]
    for linha, coluna in posicoes:
        luzes[linha][coluna] = 1
    return {"luzes": luzes, "carimbos": SO_CRUZ}


# Valores conhecidos do clássico 5x5: só o centro aceso tem 4 soluções, e a
# menor tem 11 cliques; só o canto aceso não tem solução.
CENTRO_ACESO = com_luzes_acesas((2, 2))
CANTO_ACESO = com_luzes_acesas((0, 0))
RESOLVIDA = com_luzes_acesas()


# --- /api/gerar ------------------------------------------------------------


def test_gerar():
    pedido = {"tamanho": 5, "dificuldade": 6, "variante": "carimbos_travas"}
    response = client.post("/api/gerar", json=pedido)
    assert response.status_code == 200
    corpo = response.json()
    assert corpo["minimo"] == 6
    assert len(corpo["fase"]["luzes"]) == 5
    assert len(corpo["fase"]["carimbos"][0]) == 5


def test_gerar_rejeita_tamanho_fora_da_faixa():
    pedido = {"tamanho": 8, "dificuldade": 6, "variante": "carimbos"}
    assert client.post("/api/gerar", json=pedido).status_code == 422


def test_gerar_rejeita_variante_desconhecida():
    pedido = {"tamanho": 5, "dificuldade": 6, "variante": "nao_existe"}
    assert client.post("/api/gerar", json=pedido).status_code == 422


def test_gerar_dificuldade_impossivel():
    # Mais cliques do que células: o Prolog recusa na hora.
    pedido = {"tamanho": 4, "dificuldade": 17, "variante": "carimbos"}
    response = client.post("/api/gerar", json=pedido)
    assert response.status_code == 422
    assert response.json()["detail"] == "Não foi possível gerar uma fase com essa dificuldade."


# --- /api/verificar --------------------------------------------------------


def test_verificar():
    response = client.post("/api/verificar", json={"fase": CENTRO_ACESO})
    assert response.status_code == 200
    assert response.json() == {"solucoes": 4, "minimo": 11}


def test_verificar_sem_solucao_nao_e_erro():
    response = client.post("/api/verificar", json={"fase": CANTO_ACESO})
    assert response.status_code == 200
    assert response.json() == {"solucoes": 0, "minimo": None}


def test_verificar_rejeita_matriz_nao_quadrada():
    fase = {"luzes": [[0, 0, 0, 0]] * 3, "carimbos": [["cruz"] * 4] * 3}
    assert client.post("/api/verificar", json={"fase": fase}).status_code == 422


def test_verificar_rejeita_carimbo_desconhecido():
    carimbos = [linha[:] for linha in SO_CRUZ]
    carimbos[0][0] = "estrela"
    fase = {"luzes": APAGADO, "carimbos": carimbos}
    assert client.post("/api/verificar", json={"fase": fase}).status_code == 422


# --- /api/dica -------------------------------------------------------------


def test_dica():
    response = client.post("/api/dica", json={"fase": CENTRO_ACESO})
    assert response.status_code == 200
    assert set(response.json()) == {"linha", "coluna"}


def test_dica_sem_solucao():
    response = client.post("/api/dica", json={"fase": CANTO_ACESO})
    assert response.status_code == 422
    assert response.json()["detail"] == "Esta fase não tem solução."


def test_dica_em_fase_resolvida():
    response = client.post("/api/dica", json={"fase": RESOLVIDA})
    assert response.status_code == 422
    assert response.json()["detail"] == "A fase já está resolvida."


# --- /api/resolver ---------------------------------------------------------


def test_resolver():
    response = client.post("/api/resolver", json={"fase": CENTRO_ACESO})
    assert response.status_code == 200
    corpo = response.json()
    assert corpo["minimo"] == 11
    assert len(corpo["cliques"]) == 11
    assert all(len(posicao) == 2 for posicao in corpo["cliques"])


def test_resolver_sem_solucao():
    response = client.post("/api/resolver", json={"fase": CANTO_ACESO})
    assert response.status_code == 422
