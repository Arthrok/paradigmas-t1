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

import Fase exposing (Celula(..), Fase, Forma(..), Luz(..), Posicao)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (attribute, class, id)


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
viewCelula _ numeroDaLinha numeroDaColuna celula =
    let
        aparencia =
            aparenciaDaCelula celula
    in
    div
        [ class (String.join " " ("tabuleiro-celula" :: aparencia.classes))
        , id (idDaCelula numeroDaLinha numeroDaColuna)
        , attribute "role" "gridcell"
        , attribute "data-linha" (String.fromInt numeroDaLinha)
        , attribute "data-coluna" (String.fromInt numeroDaColuna)
        , attribute "data-carimbo" aparencia.carimbo
        , attribute "data-luz" aparencia.luz
        ]
        [ span
            [ class "tabuleiro-celula-icone"
            , attribute "aria-hidden" "true"
            ]
            [ text aparencia.icone ]
        ]


idDaCelula : Int -> Int -> String
idDaCelula linha coluna =
    "celula-" ++ String.fromInt linha ++ "-" ++ String.fromInt coluna


type alias Aparencia =
    { carimbo : String
    , luz : String
    , icone : String
    , classes : List String
    }


aparenciaDaCelula : Celula -> Aparencia
aparenciaDaCelula celula =
    case celula of
        Ativa forma estadoDaLuz ->
            let
                ( nome, icone ) =
                    dadosDaForma forma
            in
            { carimbo = nome
            , luz = nomeDaLuz estadoDaLuz
            , icone = icone
            , classes =
                [ "tabuleiro-celula--ativa"
                , "tabuleiro-celula--" ++ nome
                , classeDaLuz estadoDaLuz
                ]
            }

        Travada estadoDaLuz ->
            { carimbo = "trava"
            , luz = nomeDaLuz estadoDaLuz
            , icone = "🔒"
            , classes =
                [ "tabuleiro-celula--travada"
                , classeDaLuz estadoDaLuz
                ]
            }


dadosDaForma : Forma -> ( String, String )
dadosDaForma forma =
    case forma of
        Cruz ->
            ( "cruz", "✚" )

        Xis ->
            ( "xis", "✖" )

        Linha ->
            ( "linha", "━" )

        Coluna ->
            ( "coluna", "┃" )

        Bloco ->
            ( "bloco", "▣" )


nomeDaLuz : Luz -> String
nomeDaLuz estadoDaLuz =
    case estadoDaLuz of
        Acesa ->
            "acesa"

        Apagada ->
            "apagada"


classeDaLuz : Luz -> String
classeDaLuz estadoDaLuz =
    "tabuleiro-celula--" ++ nomeDaLuz estadoDaLuz
