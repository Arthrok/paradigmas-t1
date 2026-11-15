module FaseTest exposing (suite)

{-| Testes do domínio do jogo.

Os testes `fuzz` geram centenas de fases e posições aleatórias e conferem
PROPRIEDADES que valem para qualquer entrada. Duas delas são as mesmas que
justificam o modelo de restrições do Prolog (backend/prolog/solver.pl):

  - clicar duas vezes na mesma célula é o mesmo que não clicar;
  - a ordem dos cliques não importa.

-}

import Expect exposing (Expectation)
import Fase exposing (Celula(..), Fase, Forma(..), Luz(..), Posicao)
import Fuzz exposing (Fuzzer)
import Test exposing (Test, describe, fuzz, fuzz2, fuzz3, test)


suite : Test
suite =
    describe "Fase"
        [ propriedades
        , carimbos
        , criacao
        ]



-- PROPRIEDADES


propriedades : Test
propriedades =
    describe "propriedades do clique"
        [ fuzz2 faseAleatoria posicaoAleatoria "apertar duas vezes desfaz o clique" <|
            \f p ->
                f
                    |> Fase.apertar p
                    |> Fase.apertar p
                    |> Expect.equal f
        , fuzz3 faseAleatoria posicaoAleatoria posicaoAleatoria "a ordem dos cliques não importa" <|
            \f a b ->
                (f |> Fase.apertar a |> Fase.apertar b)
                    |> Expect.equal (f |> Fase.apertar b |> Fase.apertar a)
        , fuzz2 faseAleatoria posicaoAleatoria "célula travada não muda nada" <|
            \f p ->
                case Fase.celula p f of
                    Just (Travada _) ->
                        Fase.apertar p f |> Expect.equal f

                    _ ->
                        Expect.pass
        , fuzz faseAleatoria "clicar fora do tabuleiro não muda nada" <|
            \f ->
                Fase.apertar { linha = -1, coluna = 0 } f
                    |> Expect.equal f
        ]



-- CARIMBOS


{-| Cada forma, clicada no centro de um 5x5, afeta exatamente as células da
tabela de regras.pl.
-}
carimbos : Test
carimbos =
    describe "células afetadas por cada carimbo"
        [ test "cruz" <|
            \_ ->
                afetadasNoCentro Cruz
                    [ ( 1, 2 ), ( 2, 1 ), ( 2, 2 ), ( 2, 3 ), ( 3, 2 ) ]
        , test "xis" <|
            \_ ->
                afetadasNoCentro Xis
                    [ ( 1, 1 ), ( 1, 3 ), ( 2, 2 ), ( 3, 1 ), ( 3, 3 ) ]
        , test "linha" <|
            \_ ->
                afetadasNoCentro Linha
                    [ ( 2, 0 ), ( 2, 1 ), ( 2, 2 ), ( 2, 3 ), ( 2, 4 ) ]
        , test "coluna" <|
            \_ ->
                afetadasNoCentro Coluna
                    [ ( 0, 2 ), ( 1, 2 ), ( 2, 2 ), ( 3, 2 ), ( 4, 2 ) ]
        , test "bloco" <|
            \_ ->
                afetadasNoCentro Bloco
                    [ ( 1, 1 )
                    , ( 1, 2 )
                    , ( 1, 3 )
                    , ( 2, 1 )
                    , ( 2, 2 )
                    , ( 2, 3 )
                    , ( 3, 1 )
                    , ( 3, 2 )
                    , ( 3, 3 )
                    ]
        , test "a borda corta o carimbo" <|
            \_ ->
                comFaseUniforme 5 (Ativa Cruz Apagada) <|
                    \f ->
                        Fase.afetadas { linha = 0, coluna = 0 } f
                            |> List.map paraPar
                            |> List.sort
                            |> Expect.equal [ ( 0, 0 ), ( 0, 1 ), ( 1, 0 ) ]
        , test "resolvida quando tudo está apagado" <|
            \_ ->
                comFaseUniforme 4 (Ativa Cruz Apagada) <|
                    \f ->
                        Fase.resolvida f
                            |> Expect.equal True
        , test "um clique num tabuleiro apagado acende luzes" <|
            \_ ->
                comFaseUniforme 4 (Ativa Cruz Apagada) <|
                    \f ->
                        Fase.apertar { linha = 1, coluna = 1 } f
                            |> Fase.resolvida
                            |> Expect.equal False
        ]


{-| Clica no centro de um 5x5 em que todas as células têm a mesma forma e
confere as posições afetadas.
-}
afetadasNoCentro : Forma -> List ( Int, Int ) -> Expectation
afetadasNoCentro forma esperadas =
    comFaseUniforme 5 (Ativa forma Apagada) <|
        \f ->
            Fase.afetadas { linha = 2, coluna = 2 } f
                |> List.map paraPar
                |> List.sort
                |> Expect.equal esperadas


paraPar : Posicao -> ( Int, Int )
paraPar { linha, coluna } =
    ( linha, coluna )



-- CRIAÇÃO


criacao : Test
criacao =
    describe "criar"
        [ test "aceita um tabuleiro 5x5" <|
            \_ ->
                Fase.criar (List.repeat 5 (List.repeat 5 (Travada Apagada)))
                    |> Result.map Fase.tamanho
                    |> Expect.equal (Ok 5)
        , test "rejeita tabuleiro pequeno demais" <|
            \_ ->
                Fase.criar (List.repeat 3 (List.repeat 3 (Travada Apagada)))
                    |> Expect.err
        , test "rejeita tabuleiro grande demais" <|
            \_ ->
                Fase.criar (List.repeat 7 (List.repeat 7 (Travada Apagada)))
                    |> Expect.err
        , test "rejeita tabuleiro que não é quadrado" <|
            \_ ->
                Fase.criar (List.repeat 5 (List.repeat 4 (Travada Apagada)))
                    |> Expect.err
        ]



-- FUZZERS E AUXILIARES


{-| Uma fase válida qualquer: tamanho de 4 a 6, células sorteadas.
-}
faseAleatoria : Fuzzer Fase
faseAleatoria =
    Fuzz.intRange Fase.tamanhoMinimo Fase.tamanhoMaximo
        |> Fuzz.andThen (\n -> Fuzz.listOfLength n (Fuzz.listOfLength n celulaAleatoria))
        |> Fuzz.andThen
            (\celulas ->
                case Fase.criar celulas of
                    Ok f ->
                        Fuzz.constant f

                    Err erro ->
                        Fuzz.invalid erro
            )


celulaAleatoria : Fuzzer Celula
celulaAleatoria =
    Fuzz.oneOf
        [ Fuzz.map2 Ativa formaAleatoria luzAleatoria
        , Fuzz.map Travada luzAleatoria
        ]


formaAleatoria : Fuzzer Forma
formaAleatoria =
    Fuzz.oneOfValues [ Cruz, Xis, Linha, Coluna, Bloco ]


luzAleatoria : Fuzzer Luz
luzAleatoria =
    Fuzz.oneOfValues [ Acesa, Apagada ]


{-| Posições de 0 a 3 existem em qualquer tabuleiro (o menor é 4x4).
-}
posicaoAleatoria : Fuzzer Posicao
posicaoAleatoria =
    Fuzz.map2 Posicao (Fuzz.intRange 0 3) (Fuzz.intRange 0 3)


{-| Cria uma fase NxN com a mesma célula em todo lugar e passa para a
verificação. Se `criar` recusar a fase, o teste falha com a mensagem dele.
-}
comFaseUniforme : Int -> Celula -> (Fase -> Expectation) -> Expectation
comFaseUniforme n c verificar =
    case Fase.criar (List.repeat n (List.repeat n c)) of
        Ok f ->
            verificar f

        Err erro ->
            Expect.fail erro
