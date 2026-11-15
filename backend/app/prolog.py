"""Ponte entre Python e Prolog usando a biblioteca janus.

O janus (pacote `janus-swi`) roda o SWI-Prolog dentro do próprio processo
Python: chamamos predicados diretamente e recebemos as respostas como
dicionários. Este é o ÚNICO arquivo do backend que conhece o janus.

O Python só conversa com o módulo `fronteira.pl`. Os demais módulos Prolog
(regras, solver, gerador) ficam escondidos atrás dele.
"""

from pathlib import Path

import janus_swi as janus

PROLOG_DIR = Path(__file__).parent.parent / "prolog"

# Carrega a fronteira, que por sua vez carrega os outros módulos Prolog.
janus.consult(str(PROLOG_DIR / "fronteira.pl"))
