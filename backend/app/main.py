"""API HTTP do Carimbó.

Esta camada é só "cola": recebe JSON, valida o FORMATO com Pydantic, chama o
Prolog (via app/prolog.py) e devolve JSON. Nenhuma regra do jogo mora aqui.
O contrato das rotas está em docs/api.md.

Rodar em modo de desenvolvimento (recarrega ao salvar):
    uv run fastapi dev app/main.py

Documentação interativa: http://localhost:8000/docs
"""

from typing import Annotated, Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, model_validator

from app import prolog

app = FastAPI(title="Carimbó (Prolog + Elm)")

TAMANHO_MINIMO = 4
TAMANHO_MAXIMO = 6

# Mensagens que o Elm mostra na tela quando a resposta é 422.
NAO_GEROU = "Não foi possível gerar uma fase com essa dificuldade."
SEM_SOLUCAO = "Esta fase não tem solução."
JA_RESOLVIDA = "A fase já está resolvida."


# ---------------------------------------------------------------------------
# Formato dos dados. O Pydantic rejeita (erro 422) tudo o que não bate.
# ---------------------------------------------------------------------------

Luz = Annotated[int, Field(ge=0, le=1)]
Carimbo = Literal["cruz", "xis", "linha", "coluna", "bloco", "trava"]
Variante = Literal["classico", "carimbos", "carimbos_travas"]
Posicao = tuple[int, int]  # vira [linha, coluna] no JSON


class Fase(BaseModel):
    luzes: list[list[Luz]]
    carimbos: list[list[Carimbo]]

    @model_validator(mode="after")
    def matrizes_quadradas_do_mesmo_tamanho(self) -> "Fase":
        n = len(self.luzes)
        if not TAMANHO_MINIMO <= n <= TAMANHO_MAXIMO:
            raise ValueError(f"o tabuleiro deve ter de {TAMANHO_MINIMO} a {TAMANHO_MAXIMO} linhas")
        for matriz in (self.luzes, self.carimbos):
            if len(matriz) != n or any(len(linha) != n for linha in matriz):
                raise ValueError("luzes e carimbos devem ser matrizes NxN do mesmo tamanho")
        return self


class GerarPedido(BaseModel):
    tamanho: int = Field(ge=TAMANHO_MINIMO, le=TAMANHO_MAXIMO)
    dificuldade: int = Field(ge=1)
    variante: Variante


class PedidoComFase(BaseModel):
    fase: Fase


class GerarResposta(BaseModel):
    fase: Fase
    minimo: int


class VerificarResposta(BaseModel):
    solucoes: int
    minimo: int | None


class DicaResposta(BaseModel):
    linha: int
    coluna: int


class ResolverResposta(BaseModel):
    cliques: list[Posicao]
    minimo: int


# ---------------------------------------------------------------------------
# Rotas: uma por feature.
# ---------------------------------------------------------------------------


@app.post("/api/gerar")
def gerar(pedido: GerarPedido) -> GerarResposta:
    """F4 + F5: uma fase nova, com solução garantida e dificuldade exata."""
    try:
        luzes, carimbos = prolog.gerar(pedido.variante, pedido.tamanho, pedido.dificuldade)
    except prolog.GeracaoFalhou:
        raise HTTPException(status_code=422, detail=NAO_GEROU) from None
    # O gerador garante que a solução mínima tem exatamente `dificuldade`
    # cliques (docs/adr/0007), então o mínimo é a própria dificuldade.
    return GerarResposta(fase=Fase(luzes=luzes, carimbos=carimbos), minimo=pedido.dificuldade)


@app.post("/api/verificar")
def verificar(pedido: PedidoComFase) -> VerificarResposta:
    """F1: quantas soluções a fase tem. "Sem solução" não é erro."""
    solucoes, minimo = prolog.verificar(pedido.fase.luzes, pedido.fase.carimbos)
    return VerificarResposta(solucoes=solucoes, minimo=minimo)


@app.post("/api/dica")
def dica(pedido: PedidoComFase) -> DicaResposta:
    """F2: um próximo clique correto, a partir do estado atual."""
    try:
        linha, coluna = prolog.dica(pedido.fase.luzes, pedido.fase.carimbos)
    except prolog.SemSolucao:
        raise HTTPException(status_code=422, detail=SEM_SOLUCAO) from None
    except prolog.FaseResolvida:
        raise HTTPException(status_code=422, detail=JA_RESOLVIDA) from None
    return DicaResposta(linha=linha, coluna=coluna)


@app.post("/api/resolver")
def resolver(pedido: PedidoComFase) -> ResolverResposta:
    """F3: a solução com menos cliques."""
    try:
        cliques, minimo = prolog.resolver(pedido.fase.luzes, pedido.fase.carimbos)
    except prolog.SemSolucao:
        raise HTTPException(status_code=422, detail=SEM_SOLUCAO) from None
    return ResolverResposta(cliques=cliques, minimo=minimo)
