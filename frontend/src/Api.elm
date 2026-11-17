module Api exposing
    ( Remoto(..)
    , Variante(..)
    , dica
    , encodeFase
    , faseDecoder
    , gerar
    , resolver
    , verificar
    )

import Fase exposing (Celula(..), Forma(..), Luz(..), Posicao)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Remoto a
    = NaoPedido
    | Carregando
    | Sucesso a
    | Falha String


type Variante
    = Classico
    | Carimbos
    | CarimbosTravas


gerar :
    { tamanho : Int, dificuldade : Int, variante : Variante }
    -> (Result String { fase : Fase.Fase, minimo : Int } -> msg)
    -> Cmd msg
gerar pedido toMsg =
    requisicao "gerar"
        (Encode.object
            [ ( "tamanho", Encode.int pedido.tamanho )
            , ( "dificuldade", Encode.int pedido.dificuldade )
            , ( "variante", Encode.string (varianteParaString pedido.variante) )
            ]
        )
        (Decode.map2 (\fase minimo -> { fase = fase, minimo = minimo })
            (Decode.field "fase" faseDecoder)
            (Decode.field "minimo" Decode.int)
        )
        toMsg


verificar :
    Fase.Fase
    -> (Result String { solucoes : Int, minimo : Maybe Int } -> msg)
    -> Cmd msg
verificar fase toMsg =
    requisicao "verificar"
        (pedidoComFase fase)
        (Decode.map2 (\solucoes minimo -> { solucoes = solucoes, minimo = minimo })
            (Decode.field "solucoes" Decode.int)
            (Decode.field "minimo" (Decode.nullable Decode.int))
        )
        toMsg


dica : Fase.Fase -> (Result String Posicao -> msg) -> Cmd msg
dica fase toMsg =
    requisicao "dica"
        (pedidoComFase fase)
        (Decode.map2 Posicao
            (Decode.field "linha" Decode.int)
            (Decode.field "coluna" Decode.int)
        )
        toMsg


resolver :
    Fase.Fase
    -> (Result String { cliques : List Posicao, minimo : Int } -> msg)
    -> Cmd msg
resolver fase toMsg =
    requisicao "resolver"
        (pedidoComFase fase)
        (Decode.map2 (\cliques minimo -> { cliques = cliques, minimo = minimo })
            (Decode.field "cliques" (Decode.list posicaoDecoder))
            (Decode.field "minimo" Decode.int)
        )
        toMsg


faseDecoder : Decoder Fase.Fase
faseDecoder =
    Decode.map2 construirFase
        (Decode.field "luzes" (Decode.list (Decode.list Decode.int)))
        (Decode.field "carimbos" (Decode.list (Decode.list Decode.string)))
        |> Decode.andThen resultadoDecoder


encodeFase : Fase.Fase -> Encode.Value
encodeFase fase =
    Encode.object
        [ ( "luzes"
          , Encode.list (Encode.list Encode.int)
                (List.map (List.map (luzParaInt << celulaLuz)) (Fase.linhas fase))
          )
        , ( "carimbos"
          , Encode.list (Encode.list Encode.string)
                (List.map (List.map celulaParaCarimbo) (Fase.linhas fase))
          )
        ]


construirFase : List (List Int) -> List (List String) -> Result String Fase.Fase
construirFase luzes carimbos =
    combinarLinhas luzes carimbos
        |> Result.andThen Fase.criar


combinarLinhas :
    List (List Int)
    -> List (List String)
    -> Result String (List (List Celula))
combinarLinhas luzes carimbos =
    case ( luzes, carimbos ) of
        ( [], [] ) ->
            Ok []

        ( luzesLinha :: outrasLuzes, carimbosLinha :: outrosCarimbos ) ->
            combinarLinha luzesLinha carimbosLinha
                |> Result.andThen
                    (\linha ->
                        combinarLinhas outrasLuzes outrosCarimbos
                            |> Result.map (\resto -> linha :: resto)
                    )

        _ ->
            Err "luzes e carimbos devem ter o mesmo formato."


combinarLinha : List Int -> List String -> Result String (List Celula)
combinarLinha luzes carimbos =
    case ( luzes, carimbos ) of
        ( [], [] ) ->
            Ok []

        ( luz :: outrasLuzes, carimbo :: outrosCarimbos ) ->
            celula luz carimbo
                |> Result.andThen
                    (\c ->
                        combinarLinha outrasLuzes outrosCarimbos
                            |> Result.map (\resto -> c :: resto)
                    )

        _ ->
            Err "luzes e carimbos devem ter o mesmo formato."


celula : Int -> String -> Result String Celula
celula luz carimbo =
    let
        luzConvertida =
            case luz of
                0 ->
                    Ok Apagada

                1 ->
                    Ok Acesa

                _ ->
                    Err "a luz deve ser 0 ou 1."
    in
    luzConvertida
        |> Result.andThen
            (\l ->
                case forma carimbo of
                    Ok formaConvertida ->
                        Ok (Ativa formaConvertida l)

                    Err _ ->
                        if carimbo == "trava" then
                            Ok (Travada l)

                        else
                            Err ("carimbo desconhecido: " ++ carimbo)
            )


forma : String -> Result String Forma
forma carimbo =
    case carimbo of
        "cruz" ->
            Ok Cruz

        "xis" ->
            Ok Xis

        "linha" ->
            Ok Linha

        "coluna" ->
            Ok Coluna

        "bloco" ->
            Ok Bloco

        _ ->
            Err "carimbo desconhecido."


resultadoDecoder : Result String Fase.Fase -> Decoder Fase.Fase
resultadoDecoder resultado =
    case resultado of
        Ok fase ->
            Decode.succeed fase

        Err mensagem ->
            Decode.fail mensagem


posicaoDecoder : Decoder Posicao
posicaoDecoder =
    Decode.map2 Posicao
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)


pedidoComFase : Fase.Fase -> Encode.Value
pedidoComFase fase =
    Encode.object [ ( "fase", encodeFase fase ) ]


varianteParaString : Variante -> String
varianteParaString variante =
    case variante of
        Classico ->
            "classico"

        Carimbos ->
            "carimbos"

        CarimbosTravas ->
            "carimbos_travas"


requisicao :
    String
    -> Encode.Value
    -> Decoder resposta
    -> (Result String resposta -> msg)
    -> Cmd msg
requisicao rota corpo decoder toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/api/" ++ rota
        , body = Http.jsonBody corpo
        , expect = expectApi decoder toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


expectApi :
    Decoder resposta
    -> (Result String resposta -> msg)
    -> Http.Expect msg
expectApi decoder toMsg =
    Http.expectStringResponse
        (Result.mapError erroHttp >> Result.andThen identity >> toMsg)
        (interpretarResposta decoder)


interpretarResposta :
    Decoder resposta
    -> Http.Response String
    -> Result Http.Error (Result String resposta)
interpretarResposta decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata corpo ->
            if metadata.statusCode == 422 then
                Ok (Err (detalheOuMensagem corpo))

            else
                Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata corpo ->
            case Decode.decodeString decoder corpo of
                Ok valor ->
                    Ok (Ok valor)

                Err erro ->
                    Err (Http.BadBody (Decode.errorToString erro))


detalheOuMensagem : String -> String
detalheOuMensagem corpo =
    case Decode.decodeString (Decode.field "detail" Decode.string) corpo of
        Ok detalhe ->
            detalhe

        Err _ ->
            "A API retornou um erro 422."


erroHttp : Http.Error -> String
erroHttp erro =
    case erro of
        Http.BadUrl url ->
            "URL inválida: " ++ url

        Http.Timeout ->
            "A requisição expirou."

        Http.NetworkError ->
            "Não foi possível conectar à API."

        Http.BadStatus status ->
            "A API retornou HTTP " ++ String.fromInt status ++ "."

        Http.BadBody mensagem ->
            "Resposta inválida da API: " ++ mensagem


celulaLuz : Celula -> Luz
celulaLuz celulaAtual =
    Fase.luz celulaAtual


luzParaInt : Luz -> Int
luzParaInt luz =
    case luz of
        Acesa ->
            1

        Apagada ->
            0


celulaParaCarimbo : Celula -> String
celulaParaCarimbo celulaAtual =
    case celulaAtual of
        Ativa formaAtual _ ->
            formaParaString formaAtual

        Travada _ ->
            "trava"


formaParaString : Forma -> String
formaParaString formaAtual =
    case formaAtual of
        Cruz ->
            "cruz"

        Xis ->
            "xis"

        Linha ->
            "linha"

        Coluna ->
            "coluna"

        Bloco ->
            "bloco"
