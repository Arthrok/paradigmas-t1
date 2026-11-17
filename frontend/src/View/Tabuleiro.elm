module View.Tabuleiro exposing
    ( Config
    , view
    )

{-| Estrutura visual do tabuleiro do Carimbó.

Este módulo não guarda estado. Ele recebe uma `Fase`, desenha suas linhas e
células e comunica interações ao módulo pai por meio de `Config`.


# Configuração

@docs Config


# View

@docs view

-}

import Fase exposing (Celula, Fase, Posicao)
import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class)


{-| Informa à view como emitir eventos e quais realces deve apresentar.

Os campos de interação serão usados nas próximas partes da issue. Mantê-los no
contrato desde o início permite que `Main` e a view evoluam em paralelo.

-}
type alias Config msg =
    { aoClicar : Posicao -> msg
    , aoPassar : Maybe Posicao -> msg
    , posicaoEmFoco : Maybe Posicao
    , dica : Maybe Posicao
    , bloqueado : Bool
    }


{-| Desenha todas as linhas e células de uma fase.
-}
view : Config msg -> Fase -> Html msg
view config fase =
    div
        [ class "tabuleiro"
        , attribute "role" "grid"
        , attribute "data-tamanho" (String.fromInt (Fase.tamanho fase))
        ]
        (Fase.linhas fase
            |> List.indexedMap (viewLinha config)
        )


viewLinha : Config msg -> Int -> List Celula -> Html msg
viewLinha config numeroDaLinha celulas =
    div
        [ class "tabuleiro-linha"
        , attribute "role" "row"
        , attribute "data-linha" (String.fromInt numeroDaLinha)
        ]
        (celulas
            |> List.indexedMap (viewCelula config numeroDaLinha)
        )


viewCelula : Config msg -> Int -> Int -> Celula -> Html msg
viewCelula _ numeroDaLinha numeroDaColuna _ =
    div
        [ class "tabuleiro-celula"
        , attribute "role" "gridcell"
        , attribute "data-linha" (String.fromInt numeroDaLinha)
        , attribute "data-coluna" (String.fromInt numeroDaColuna)
        ]
        []
