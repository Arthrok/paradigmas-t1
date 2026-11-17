module TabuleiroTest exposing (suite)

import Expect exposing (Expectation)
import Fase exposing (Celula(..), Luz(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import View.Tabuleiro as Tabuleiro


type Msg
    = Ignorar


suite : Test
suite =
    describe "View.Tabuleiro"
        [ test "renderiza as 16 células de uma fase 4x4" <|
            \_ -> contarCelulas 4
        , test "renderiza as 25 células de uma fase 5x5" <|
            \_ -> contarCelulas 5
        , test "renderiza as 36 células de uma fase 6x6" <|
            \_ -> contarCelulas 6
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


config : Tabuleiro.Config Msg
config =
    { aoClicar = \_ -> Ignorar
    , aoPassar = \_ -> Ignorar
    , posicaoEmFoco = Nothing
    , dica = Nothing
    , bloqueado = False
    }
