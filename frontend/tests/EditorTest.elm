module EditorTest exposing (suite)

import Editor exposing (Ferramenta(..))
import Expect
import Fase exposing (Celula(..), Forma(..), Luz(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Editor"
        [ test "emBranco cria fase apagada do tamanho pedido" <|
            \_ ->
                Editor.emBranco 5
                    |> Result.map (\f -> ( Fase.tamanho f, Fase.resolvida f ))
                    |> Expect.equal (Ok ( 5, True ))
        , test "emBranco rejeita tamanho inválido" <|
            \_ ->
                Editor.emBranco 1 |> Expect.err
        , test "AlternarLuz acende uma célula apagada" <|
            \_ ->
                celulaApos AlternarLuz
                    |> Expect.equal (Just (Ativa Cruz Acesa))
        , test "Carimbar troca a forma e mantém a luz" <|
            \_ ->
                celulaApos (Carimbar Bloco)
                    |> Expect.equal (Just (Ativa Bloco Apagada))
        , test "Travar remove o carimbo e mantém a luz" <|
            \_ ->
                celulaApos Travar
                    |> Expect.equal (Just (Travada Apagada))
        , test "Carimbar destrava uma célula travada" <|
            \_ ->
                Editor.emBranco 4
                    |> Result.andThen (Editor.aplicar Travar { linha = 1, coluna = 1 })
                    |> Result.andThen (Editor.aplicar (Carimbar Xis) { linha = 1, coluna = 1 })
                    |> Result.map (Fase.celula { linha = 1, coluna = 1 })
                    |> Expect.equal (Ok (Just (Ativa Xis Apagada)))
        , test "AlternarLuz funciona em célula travada" <|
            \_ ->
                Editor.emBranco 4
                    |> Result.andThen (Editor.aplicar Travar { linha = 0, coluna = 0 })
                    |> Result.andThen (Editor.aplicar AlternarLuz { linha = 0, coluna = 0 })
                    |> Result.map (Fase.celula { linha = 0, coluna = 0 })
                    |> Expect.equal (Ok (Just (Travada Acesa)))
        , test "só se pode jogar com solução" <|
            \_ ->
                ( Editor.podeJogar 0 Nothing
                , Editor.podeJogar 3 (Just 2)
                )
                    |> Expect.equal ( Nothing, Just 2 )
        ]


celulaApos : Ferramenta -> Maybe Celula
celulaApos ferramenta =
    Editor.emBranco 4
        |> Result.andThen (Editor.aplicar ferramenta { linha = 1, coluna = 1 })
        |> Result.toMaybe
        |> Maybe.andThen (Fase.celula { linha = 1, coluna = 1 })
