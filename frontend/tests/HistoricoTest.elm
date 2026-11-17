module HistoricoTest exposing (suite)

import Expect
import Fuzz
import Historico
import Test exposing (Test, describe, fuzz2, test)


suite : Test
suite =
    describe "Historico"
        [ propriedades
        , operacoes
        ]


propriedades : Test
propriedades =
    describe "propriedades"
        [ fuzz2 Fuzz.int Fuzz.int "desfazer avancar volta ao atual anterior" <|
            \inicial novo ->
                let
                    historico =
                        Historico.iniciar inicial

                    avancado =
                        Historico.avancar novo historico
                in
                Historico.desfazer avancado
                    |> Historico.atual
                    |> Expect.equal (Historico.atual historico)
        , test "avancar limpa o futuro" <|
            \_ ->
                let
                    historico =
                        Historico.iniciar 0
                            |> Historico.avancar 1
                            |> Historico.desfazer

                    avancado =
                        Historico.avancar 2 historico
                in
                Expect.all
                    [ \h -> Historico.atual h |> Expect.equal 2
                    , \h -> Historico.podeRefazer h |> Expect.equal False
                    ]
                    avancado
        ]


operacoes : Test
operacoes =
    describe "operacoes"
        [ test "iniciar não permite desfazer nem refazer" <|
            \_ ->
                Historico.iniciar "inicial"
                    |> Expect.all
                        [ \h -> Historico.atual h |> Expect.equal "inicial"
                        , \h -> Historico.podeDesfazer h |> Expect.equal False
                        , \h -> Historico.podeRefazer h |> Expect.equal False
                        ]
        , test "refazer recupera o estado desfeito" <|
            \_ ->
                Historico.iniciar 1
                    |> Historico.avancar 2
                    |> Historico.desfazer
                    |> Historico.refazer
                    |> Historico.atual
                    |> Expect.equal 2
        , test "desfazer e refazer sem estados não mudam o atual" <|
            \_ ->
                Historico.iniciar "estado"
                    |> Historico.desfazer
                    |> Historico.refazer
                    |> Historico.atual
                    |> Expect.equal "estado"
        ]
