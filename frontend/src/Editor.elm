module Editor exposing (Ferramenta(..), aplicar, emBranco, podeJogar)

{-| Regras puras do editor de fases (F1).

O editor não conhece `Html` nem `Http`: dado uma ferramenta, uma posição e
uma `Fase`, devolve a nova `Fase`.

@docs Ferramenta, aplicar, emBranco, podeJogar

-}

import Fase exposing (Celula(..), Fase, Forma(..), Luz(..), Posicao)


{-| O que um clique faz no tabuleiro quando se está editando.

  - `AlternarLuz`: acende/apaga a célula;
  - `Carimbar forma`: coloca o carimbo (destrava se estiver travada);
  - `Travar`: trava a célula (remove o carimbo).

-}
type Ferramenta
    = AlternarLuz
    | Carimbar Forma
    | Travar


{-| Aplica a ferramenta na célula da posição. Posição fora da fase devolve a
fase sem alteração.
-}
aplicar : Ferramenta -> Posicao -> Fase -> Result String Fase
aplicar ferramenta posicao fase =
    Fase.linhas fase
        |> List.indexedMap
            (\l linha ->
                List.indexedMap
                    (\c celula ->
                        if l == posicao.linha && c == posicao.coluna then
                            transformar ferramenta celula

                        else
                            celula
                    )
                    linha
            )
        |> Fase.criar


transformar : Ferramenta -> Celula -> Celula
transformar ferramenta celula =
    let
        luz =
            Fase.luz celula
    in
    case ferramenta of
        AlternarLuz ->
            case celula of
                Ativa forma l ->
                    Ativa forma (inverter l)

                Travada l ->
                    Travada (inverter l)

        Carimbar forma ->
            Ativa forma luz

        Travar ->
            Travada luz


inverter : Luz -> Luz
inverter luz =
    case luz of
        Acesa ->
            Apagada

        Apagada ->
            Acesa


{-| Fase do tamanho dado, toda apagada e com carimbos em cruz: ponto de partida
para desenhar.
-}
emBranco : Int -> Result String Fase
emBranco tamanho =
    Fase.criar (List.repeat tamanho (List.repeat tamanho (Ativa Cruz Apagada)))


{-| Só se pode jogar uma fase verificada que tem solução (`solucoes > 0` e
um mínimo conhecido).
-}
podeJogar : Int -> Maybe Int -> Maybe Int
podeJogar solucoes minimo =
    if solucoes > 0 then
        minimo

    else
        Nothing
