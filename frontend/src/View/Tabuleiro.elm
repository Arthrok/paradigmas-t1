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
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (attribute, class, disabled, id, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)


{-| Informa à view como emitir eventos e quais realces deve apresentar.

  - `aoClicar`: mensagem emitida por uma célula ativa;
  - `aoPassar`: informa a posição sob o ponteiro, ou `Nothing` ao sair;
  - `posicaoEmFoco`: origem da pré-visualização calculada por `Fase.afetadas`;
  - `dica`: posição sugerida pelo solver;
  - `bloqueado`: desativa interações durante carregamentos ou animações.

O estado permanece no módulo pai. A view apenas o representa e emite mensagens.

-}
type alias Config msg =
    { aoClicar : Posicao -> msg
    , aoPassar : Maybe Posicao -> msg
    , posicaoEmFoco : Maybe Posicao
    , dica : Maybe Posicao
    , bloqueado : Bool
    }


{-| Desenha todas as linhas e células de uma fase como uma grade acessível.

Cada célula ativa é um botão; travas continuam visíveis, mas não podem ser
acionadas. Luz, carimbo, prévia e dica são derivados somente de `Fase` e `Config`.

-}
view : Config msg -> Fase -> Html msg
view config fase =
    let
        tamanho =
            Fase.tamanho fase

        posicoesAfetadas =
            if config.bloqueado then
                []

            else
                case config.posicaoEmFoco of
                    Just posicao ->
                        Fase.afetadas posicao fase

                    Nothing ->
                        []
    in
    div
        [ class "tabuleiro"
        , attribute "role" "grid"
        , attribute "aria-label" "Tabuleiro do Carimbó"
        , attribute "aria-rowcount" (String.fromInt tamanho)
        , attribute "aria-colcount" (String.fromInt tamanho)
        , attribute "aria-busy" (textoBooleano config.bloqueado)
        , attribute "data-tamanho" (String.fromInt tamanho)
        ]
        (Fase.linhas fase
            |> List.indexedMap (viewLinha config posicoesAfetadas)
        )


viewLinha : Config msg -> List Posicao -> Int -> List Celula -> Html msg
viewLinha config posicoesAfetadas numeroDaLinha celulas =
    div
        [ class "tabuleiro-linha"
        , attribute "role" "row"
        , attribute "aria-rowindex" (String.fromInt (numeroDaLinha + 1))
        , attribute "data-linha" (String.fromInt numeroDaLinha)
        ]
        (celulas
            |> List.indexedMap (viewCelula config posicoesAfetadas numeroDaLinha)
        )


viewCelula : Config msg -> List Posicao -> Int -> Int -> Celula -> Html msg
viewCelula config posicoesAfetadas numeroDaLinha numeroDaColuna celula =
    let
        aparencia =
            aparenciaDaCelula celula

        posicao =
            { linha = numeroDaLinha, coluna = numeroDaColuna }

        estaBloqueada =
            config.bloqueado || ehTravada celula

        estaAfetada =
            List.member posicao posicoesAfetadas

        estaEmFoco =
            not estaBloqueada && config.posicaoEmFoco == Just posicao

        temDica =
            config.dica == Just posicao

        descricao =
            descricaoDaCelula posicao celula temDica

        classes =
            aparencia.classes
                |> adicionarClasseSe config.bloqueado "tabuleiro-celula--bloqueada"
                |> adicionarClasseSe estaAfetada "tabuleiro-celula--afetada"
                |> adicionarClasseSe estaEmFoco "tabuleiro-celula--foco"
                |> adicionarClasseSe temDica "tabuleiro-celula--dica"
    in
    div
        [ class (String.join " " ("tabuleiro-celula" :: classes))
        , id (idDaCelula numeroDaLinha numeroDaColuna)
        , attribute "role" "gridcell"
        , attribute "aria-colindex" (String.fromInt (numeroDaColuna + 1))
        , attribute "data-linha" (String.fromInt numeroDaLinha)
        , attribute "data-coluna" (String.fromInt numeroDaColuna)
        , attribute "data-carimbo" aparencia.carimbo
        , attribute "data-luz" aparencia.luz
        ]
        (button
            (atributosDoBotao config posicao estaBloqueada descricao)
            [ span
                [ class "tabuleiro-celula-icone"
                , attribute "aria-hidden" "true"
                ]
                [ text aparencia.icone ]
            ]
            :: indicadorDaDica temDica
        )


indicadorDaDica : Bool -> List (Html msg)
indicadorDaDica temDica =
    if temDica then
        [ span
            [ class "tabuleiro-celula-dica"
            , attribute "aria-hidden" "true"
            ]
            [ text "💡" ]
        ]

    else
        []


atributosDoBotao : Config msg -> Posicao -> Bool -> String -> List (Html.Attribute msg)
atributosDoBotao config posicao estaBloqueada descricao =
    [ class "tabuleiro-celula-botao"
    , type_ "button"
    , disabled estaBloqueada
    , attribute "aria-label" descricao
    ]
        ++ (if estaBloqueada then
                []

            else
                [ onClick (config.aoClicar posicao)
                , onMouseEnter (config.aoPassar (Just posicao))
                , onMouseLeave (config.aoPassar Nothing)
                ]
           )


descricaoDaCelula : Posicao -> Celula -> Bool -> String
descricaoDaCelula posicao celula temDica =
    let
        coordenadas =
            "Linha "
                ++ String.fromInt (posicao.linha + 1)
                ++ ", coluna "
                ++ String.fromInt (posicao.coluna + 1)

        descricao =
            case celula of
                Ativa forma estadoDaLuz ->
                    coordenadas
                        ++ ", luz "
                        ++ nomeDaLuz estadoDaLuz
                        ++ ", carimbo "
                        ++ Tuple.first (dadosDaForma forma)

                Travada estadoDaLuz ->
                    coordenadas
                        ++ ", célula travada, luz "
                        ++ nomeDaLuz estadoDaLuz
    in
    if temDica then
        descricao ++ ", dica sugerida"

    else
        descricao


textoBooleano : Bool -> String
textoBooleano valor =
    if valor then
        "true"

    else
        "false"


adicionarClasseSe : Bool -> String -> List String -> List String
adicionarClasseSe condicao nomeDaClasse classes =
    if condicao then
        nomeDaClasse :: classes

    else
        classes


ehTravada : Celula -> Bool
ehTravada celula =
    case celula of
        Travada _ ->
            True

        Ativa _ _ ->
            False


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
