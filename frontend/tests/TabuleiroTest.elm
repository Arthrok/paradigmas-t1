module TabuleiroTest exposing (suite)

import Expect exposing (Expectation)
import Fase exposing (Celula(..), Fase, Forma(..), Luz(..))
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import View.Tabuleiro as Tabuleiro


type Msg
    = Clicou Fase.Posicao
    | Passou (Maybe Fase.Posicao)


suite : Test
suite =
    describe "View.Tabuleiro"
        [ test "renderiza as 16 células de uma fase 4x4" <|
            \_ -> contarCelulas 4
        , test "renderiza as 25 células de uma fase 5x5" <|
            \_ -> contarCelulas 5
        , test "renderiza as 36 células de uma fase 6x6" <|
            \_ -> contarCelulas 6
        , test "representa os cinco carimbos e a trava" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        Expect.all
                            [ \_ -> celulaTem fase 0 0 "tabuleiro-celula--cruz" "✚"
                            , \_ -> celulaTem fase 0 1 "tabuleiro-celula--xis" "✖"
                            , \_ -> celulaTem fase 0 2 "tabuleiro-celula--linha" "━"
                            , \_ -> celulaTem fase 0 3 "tabuleiro-celula--coluna" "┃"
                            , \_ -> celulaTem fase 0 4 "tabuleiro-celula--bloco" "▣"
                            , \_ -> celulaTem fase 0 5 "tabuleiro-celula--travada" "🔒"
                            ]
                            ()
        , test "diferencia luz acesa e apagada" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        Expect.all
                            [ \_ -> celulaTem fase 0 0 "tabuleiro-celula--acesa" "✚"
                            , \_ -> celulaTem fase 0 1 "tabuleiro-celula--apagada" "✖"
                            ]
                            ()
        , test "célula ativa emite a posição clicada" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        botaoNaPosicao config fase 0 2
                            |> Event.simulate Event.click
                            |> Event.expect (Clicou { linha = 0, coluna = 2 })
        , test "célula travada fica desabilitada" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        botaoNaPosicao config fase 0 5
                            |> Query.has [ Selector.disabled True ]
        , test "configuração bloqueada desabilita células ativas" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        botaoNaPosicao { config | bloqueado = True } fase 0 0
                            |> Query.has [ Selector.disabled True ]
        , test "entrar numa célula ativa informa sua posição" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        botaoNaPosicao config fase 0 2
                            |> Event.simulate Event.mouseEnter
                            |> Event.expect (Passou (Just { linha = 0, coluna = 2 }))
        , test "sair de uma célula ativa limpa o foco" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        botaoNaPosicao config fase 0 2
                            |> Event.simulate Event.mouseLeave
                            |> Event.expect (Passou Nothing)
        , test "prévia no canto respeita as bordas do tabuleiro" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        Tabuleiro.view { config | posicaoEmFoco = Just { linha = 0, coluna = 0 } } fase
                            |> Query.fromHtml
                            |> Query.findAll [ Selector.class "tabuleiro-celula--afetada" ]
                            |> Query.count (Expect.equal 3)
        , test "prévia destaca uma trava afetada por outro carimbo" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        Tabuleiro.view { config | posicaoEmFoco = Just { linha = 0, coluna = 4 } } fase
                            |> Query.fromHtml
                            |> Query.find [ Selector.id "celula-0-5" ]
                            |> Query.has [ Selector.class "tabuleiro-celula--afetada" ]
        , test "passar sobre uma trava não cria prévia" <|
            \_ ->
                comFaseDeCarimbos <|
                    \fase ->
                        Tabuleiro.view { config | posicaoEmFoco = Just { linha = 0, coluna = 5 } } fase
                            |> Query.fromHtml
                            |> Query.findAll [ Selector.class "tabuleiro-celula--afetada" ]
                            |> Query.count (Expect.equal 0)
        ]


contarCelulas : Int -> Expectation
contarCelulas n =
    case Fase.criar (List.repeat n (List.repeat n (Travada Apagada))) of
        Ok fase ->
            Tabuleiro.view config fase
                |> Query.fromHtml
                |> Query.findAll [ Selector.class "tabuleiro-celula" ]
                |> Query.count (Expect.equal (n * n))

        Err erro ->
            Expect.fail erro


comFaseDeCarimbos : (Fase -> Expectation) -> Expectation
comFaseDeCarimbos verificar =
    let
        primeiraLinha =
            [ Ativa Cruz Acesa
            , Ativa Xis Apagada
            , Ativa Linha Acesa
            , Ativa Coluna Apagada
            , Ativa Bloco Acesa
            , Travada Apagada
            ]

        demaisLinhas =
            List.repeat 5 (List.repeat 6 (Ativa Cruz Apagada))
    in
    case Fase.criar (primeiraLinha :: demaisLinhas) of
        Ok fase ->
            verificar fase

        Err erro ->
            Expect.fail erro


celulaTem : Fase -> Int -> Int -> String -> String -> Expectation
celulaTem fase linha coluna classe icone =
    Tabuleiro.view config fase
        |> Query.fromHtml
        |> Query.find [ Selector.id ("celula-" ++ String.fromInt linha ++ "-" ++ String.fromInt coluna) ]
        |> Query.has
            [ Selector.class classe
            , Selector.text icone
            ]


botaoNaPosicao : Tabuleiro.Config Msg -> Fase -> Int -> Int -> Query.Single Msg
botaoNaPosicao configuracao fase linha coluna =
    Tabuleiro.view configuracao fase
        |> Query.fromHtml
        |> Query.find [ Selector.id ("celula-" ++ String.fromInt linha ++ "-" ++ String.fromInt coluna) ]
        |> Query.find [ Selector.tag "button" ]


config : Tabuleiro.Config Msg
config =
    { aoClicar = Clicou
    , aoPassar = Passou
    , posicaoEmFoco = Nothing
    , dica = Nothing
    , bloqueado = False
    }
