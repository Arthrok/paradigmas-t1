"""Ponte entre Python e Prolog usando a biblioteca janus.

O janus (pacote `janus-swi`) roda o SWI-Prolog dentro do próprio processo
Python: chamamos predicados diretamente e recebemos as respostas como
dicionários. Este é o ÚNICO arquivo do backend que conhece o janus.

O Python só conversa com o módulo `fronteira.pl`, e cada função abaixo chama
um predicado dele. Quem decide tudo (se há solução, qual a dica...) é o
Prolog; aqui só traduzimos cada resultado para Python.

Conversões do janus usadas aqui:
    Python -> Prolog   int -> inteiro, str -> string, list -> lista
    Prolog -> Python   átomo -> str, lista -> list
"""

from pathlib import Path

import janus_swi as janus

PROLOG_DIR = Path(__file__).parent.parent / "prolog"

# Carrega a fronteira, que por sua vez carrega os outros módulos Prolog.
janus.consult(str(PROLOG_DIR / "fronteira.pl"))

Matriz = list[list]
Posicao = tuple[int, int]


class SemSolucao(Exception):
    """A fase não pode ser resolvida."""


class FaseResolvida(Exception):
    """Todas as luzes já estão apagadas: não há dica para dar."""


class GeracaoFalhou(Exception):
    """O gerador não conseguiu criar uma fase com a dificuldade pedida."""


def gerar(variante: str, tamanho: int, dificuldade: int) -> tuple[Matriz, Matriz]:
    """Gera uma fase nova. Devolve (luzes, carimbos)."""
    resposta = janus.query_once(
        "fronteira:gerar(Variante, Tamanho, Dificuldade, Luzes, Carimbos)",
        {"Variante": variante, "Tamanho": tamanho, "Dificuldade": dificuldade},
    )
    if not resposta["truth"]:
        raise GeracaoFalhou
    return resposta["Luzes"], resposta["Carimbos"]


def verificar(luzes: Matriz, carimbos: Matriz) -> tuple[int, int | None]:
    """Devolve (quantidade de soluções, mínimo de cliques ou None)."""
    resultado = _consultar("verificar", luzes, carimbos)
    # `match` escolhe o ramo pela FORMA do valor, como o casamento de
    # padrões do Prolog e do Elm.
    match resultado:
        case "sem_solucao":
            return 0, None
        case [solucoes, minimo]:
            return solucoes, minimo
    raise ValueError(f"resultado inesperado de verificar/3: {resultado!r}")


def dica(luzes: Matriz, carimbos: Matriz) -> Posicao:
    resultado = _consultar("dica", luzes, carimbos)
    match resultado:
        case "sem_solucao":
            raise SemSolucao
        case "resolvida":
            raise FaseResolvida
        case [linha, coluna]:
            return linha, coluna
    raise ValueError(f"resultado inesperado de dica/3: {resultado!r}")


def resolver(luzes: Matriz, carimbos: Matriz) -> tuple[list[Posicao], int]:
    """Devolve (cliques da solução mínima, quantidade de cliques)."""
    resultado = _consultar("resolver", luzes, carimbos)
    match resultado:
        case "sem_solucao":
            raise SemSolucao
        case [cliques, minimo]:
            return [(linha, coluna) for linha, coluna in cliques], minimo
    raise ValueError(f"resultado inesperado de resolver/3: {resultado!r}")


def _consultar(predicado: str, luzes: Matriz, carimbos: Matriz):
    """Chama fronteira:<predicado>(Luzes, Carimbos, Resultado)."""
    resposta = janus.query_once(
        f"fronteira:{predicado}(Luzes, Carimbos, Resultado)",
        {"Luzes": luzes, "Carimbos": carimbos},
    )
    return resposta["Resultado"]
