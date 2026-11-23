module ApiTest exposing (suite)

import Api
import Dict
import Expect
import Fase
import Http
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
        , test "422 sem solução preserva a mensagem da API" <|
            \_ ->
                resposta422 "Esta fase não tem solução."
                    |> Expect.equal (Ok (Err "Esta fase não tem solução."))
        , test "422 em fase resolvida preserva a mensagem da API" <|
            \_ ->
                resposta422 "A fase já está resolvida."
                    |> Expect.equal (Ok (Err "A fase já está resolvida."))
        , test "backend fora do ar vira erro de rede" <|
            \_ ->
                Api.interpretarResposta (Json.Decode.succeed ())
                    Http.NetworkError_
                    |> Expect.equal (Err Http.NetworkError)
        , test "backend que demora demais vira erro de timeout" <|
            \_ ->
                Api.interpretarResposta (Json.Decode.succeed ())
                    Http.Timeout_
                    |> Expect.equal (Err Http.Timeout)
        ]


resposta422 : String -> Result Http.Error (Result String ())
resposta422 detalhe =
    Api.interpretarResposta (Json.Decode.succeed ())
        (Http.BadStatus_
            { url = "/api/dica"
            , statusCode = 422
            , statusText = "Unprocessable Entity"
            , headers = Dict.empty
            }
            (Json.Encode.object [ ( "detail", Json.Encode.string detalhe ) ]
                |> Json.Encode.encode 0
            )
        )


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
