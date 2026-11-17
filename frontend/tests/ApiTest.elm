module ApiTest exposing (suite)

import Api
import Expect
import Fase
import Json.Decode
import Json.Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Api"
        [ test "decodifica o exemplo de fase da API" <|
            \_ ->
                Json.Decode.decodeString Api.faseDecoder faseJson
                    |> Result.map Fase.tamanho
                    |> Expect.equal (Ok 5)
        , test "rejeita carimbo desconhecido" <|
            \_ ->
                Json.Decode.decodeString Api.faseDecoder
                    (String.replace "cruz" "triangulo" faseJson)
                    |> Expect.err
        , test "codifica luzes e carimbos" <|
            \_ ->
                case Fase.criar (List.repeat 4 (List.repeat 4 (Fase.Ativa Fase.Cruz Fase.Acesa))) of
                    Ok fase ->
                        Api.encodeFase fase
                            |> Json.Encode.encode 0
                            |> Expect.equal
                                "{\"luzes\":[[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]],\"carimbos\":[[\"cruz\",\"cruz\",\"cruz\",\"cruz\"],[\"cruz\",\"cruz\",\"cruz\",\"cruz\"],[\"cruz\",\"cruz\",\"cruz\",\"cruz\"],[\"cruz\",\"cruz\",\"cruz\",\"cruz\"]]}"

                    Err mensagem ->
                        Expect.fail mensagem
        ]


faseJson : String
faseJson =
    """
    {
      "luzes": [[0, 1, 0, 0, 0], [1, 1, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 1, 0], [0, 0, 0, 0, 0]],
      "carimbos": [
        ["cruz", "xis", "trava", "linha", "cruz"],
        ["bloco", "cruz", "coluna", "xis", "cruz"],
        ["cruz", "cruz", "cruz", "cruz", "trava"],
        ["linha", "xis", "cruz", "bloco", "cruz"],
        ["cruz", "coluna", "cruz", "cruz", "xis"]
      ]
    }
    """
