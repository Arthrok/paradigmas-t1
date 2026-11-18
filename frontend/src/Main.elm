
module Main exposing (main)

import Api
import Browser
import Fase
import Historico
import Html exposing (Html, button, div, h1, h2, main_, p, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import View.Tabuleiro as Tabuleiro


-- CONFIGURACAO


type alias Config =
    { tamanho : Int
    , dificuldade : Int
    , variante : Api.Variante
    }


configInicial : Config
configInicial =
    { tamanho = 5
    , dificuldade = 8
    , variante = Api.CarimbosTravas
    }


type Modo
    = Jogar
    | Editar


-- ESTADO DO JOGO


type alias Model =
    { config : Config
    , partida : Partida
    , modo : Modo
    , posicaoEmFoco : Maybe Fase.Posicao
    }


type Partida
    = SemFase
    | Gerando
    | FalhaAoGerar String
    | Jogando Jogo
    | Vencida Jogo


type alias Jogo =
    { historico : Historico.Historico Fase.Fase
    , inicial : Fase.Fase
    , cliques : Int
    , minimo : Int
    , ajuda : Ajuda
    }


type Ajuda
    = SemAjuda
    | PedindoDica
    | Dica Fase.Posicao
    | PedindoSolucao
    | AnimandoSolucao (List Fase.Posicao)
    | ErroAjuda String
    | ResultadoVerificacao Int (Maybe Int)


-- MENSAGENS


type Msg
    = MudouConfig Config
    | NovaFase
    | FaseGerada (Result String { fase : Fase.Fase, minimo : Int })
    | Clicou Fase.Posicao
    | Desfazer
    | Refazer
    | Reiniciar
    | PedirDica
    | DicaChegou (Result String Fase.Posicao)
    | PedirSolucao
    | SolucaoChegou
        (Result String { cliques : List Fase.Posicao, minimo : Int })
    | PassoAnimacao
    | MudouModo Modo
    | EditouCelula Fase.Posicao Fase.Celula
    | Verificar
    | VerificacaoChegou
        (Result String { solucoes : Int, minimo : Maybe Int })
    | PassouSobre (Maybe Fase.Posicao)


-- INICIALIZACAO


init : () -> ( Model, Cmd Msg )
init _ =
    ( { config = configInicial
      , partida = SemFase
      , modo = Jogar
      , posicaoEmFoco = Nothing
      }
    , Cmd.none
    )


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MudouConfig novaConfig ->
            ( { model | config = novaConfig }
            , Cmd.none
            )

        NovaFase ->
            ( { model
                | partida = Gerando
                , posicaoEmFoco = Nothing
              }
            , Api.gerar model.config FaseGerada
            )

        FaseGerada resultado ->
            case resultado of
                Ok resposta ->
                    let
                        novoJogo =
                            { historico = Historico.iniciar resposta.fase
                            , inicial = resposta.fase
                            , cliques = 0
                            , minimo = resposta.minimo
                            , ajuda = SemAjuda
                            }
                    in
                    ( { model
                        | partida = Jogando novoJogo
                        , posicaoEmFoco = Nothing
                      }
                    , Cmd.none
                    )

                Err erro ->
                    ( { model
                        | partida = FalhaAoGerar erro
                        , posicaoEmFoco = Nothing
                      }
                    , Cmd.none
                    )

        Clicou posicao ->
            case model.partida of
                Jogando jogo ->
                    case Fase.celula posicao (Historico.atual jogo.historico) of
                        Just (Fase.Ativa _ _) ->
                            let
                                novaFase =
                                    Fase.apertar posicao (Historico.atual jogo.historico)

                                novoJogo =
                                    { jogo
                                        | historico =
                                            Historico.avancar novaFase jogo.historico
                                        , cliques = jogo.cliques + 1
                                        , ajuda = SemAjuda
                                    }

                                novaPartida =
                                    if Fase.resolvida novaFase then
                                        Vencida novoJogo

                                    else
                                        Jogando novoJogo
                            in
                            ( { model
                                | partida = novaPartida
                                , posicaoEmFoco = Nothing
                              }
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Desfazer ->
            case model.partida of
                Jogando jogo ->
                    if Historico.podeDesfazer jogo.historico then
                        let
                            novoHistorico =
                                Historico.desfazer jogo.historico

                            novaFase =
                                Historico.atual novoHistorico

                            novoJogo =
                                { jogo
                                    | historico = novoHistorico
                                    , cliques = max 0 (jogo.cliques - 1)
                                    , ajuda = SemAjuda
                                }

                            novaPartida =
                                if Fase.resolvida novaFase then
                                    Vencida novoJogo

                                else
                                    Jogando novoJogo
                        in
                        ( { model
                            | partida = novaPartida
                            , posicaoEmFoco = Nothing
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Vencida jogo ->
                    if Historico.podeDesfazer jogo.historico then
                        let
                            novoHistorico =
                                Historico.desfazer jogo.historico

                            novoJogo =
                                { jogo
                                    | historico = novoHistorico
                                    , cliques = max 0 (jogo.cliques - 1)
                                    , ajuda = SemAjuda
                                }
                        in
                        ( { model | partida = Jogando novoJogo }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Refazer ->
            case model.partida of
                Jogando jogo ->
                    if Historico.podeRefazer jogo.historico then
                        let
                            novoHistorico =
                                Historico.refazer jogo.historico

                            novaFase =
                                Historico.atual novoHistorico

                            novoJogo =
                                { jogo
                                    | historico = novoHistorico
                                    , cliques = jogo.cliques + 1
                                    , ajuda = SemAjuda
                                }

                            novaPartida =
                                if Fase.resolvida novaFase then
                                    Vencida novoJogo

                                else
                                    Jogando novoJogo
                        in
                        ( { model | partida = novaPartida }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Reiniciar ->
            case model.partida of
                Jogando jogo ->
                    ( { model
                        | partida = reiniciarJogo jogo
                        , posicaoEmFoco = Nothing
                      }
                    , Cmd.none
                    )

                Vencida jogo ->
                    ( { model
                        | partida = reiniciarJogo jogo
                        , posicaoEmFoco = Nothing
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        PedirDica ->
            case model.partida of
                Jogando jogo ->
                    ( { model
                        | partida =
                            Jogando { jogo | ajuda = PedindoDica }
                      }
                    , Api.dica
                        (Historico.atual jogo.historico)
                        DicaChegou
                    )

                _ ->
                    ( model, Cmd.none )

        DicaChegou resultado ->
            ( atualizarAjuda
                (\ajuda ->
                    case resultado of
                        Ok posicao ->
                            Dica posicao

                        Err erro ->
                            ErroAjuda erro
                )
                model
            , Cmd.none
            )

        PedirSolucao ->
            case model.partida of
                Jogando jogo ->
                    ( { model
                        | partida =
                            Jogando { jogo | ajuda = PedindoSolucao }
                      }
                    , Api.resolver
                        (Historico.atual jogo.historico)
                        SolucaoChegou
                    )

                _ ->
                    ( model, Cmd.none )

        SolucaoChegou resultado ->
            ( atualizarAjuda
                (\ajuda ->
                    case resultado of
                        Ok resposta ->
                            AnimandoSolucao resposta.cliques

                        Err erro ->
                            ErroAjuda erro
                )
                model
            , Cmd.none
            )

        PassoAnimacao ->
            -- A animacao automatica pode ser implementada posteriormente.
            ( model, Cmd.none )

        MudouModo novoModo ->
            ( { model
                | modo = novoModo
                , posicaoEmFoco = Nothing
              }
            , Cmd.none
            )

        EditouCelula posicao novaCelula ->
            case ( model.modo, model.partida ) of
                ( Editar, Jogando jogo ) ->
                    let
                        faseAtual =
                            Historico.atual jogo.historico

                        linhasAtualizadas =
                            Fase.linhas faseAtual
                                |> List.indexedMap
                                    (\linhaNumero linha ->
                                        if linhaNumero == posicao.linha then
                                            linha
                                                |> List.indexedMap
                                                    (\colunaNumero celula ->
                                                        if colunaNumero == posicao.coluna then
                                                            novaCelula

                                                        else
                                                            celula
                                                    )

                                        else
                                            linha
                                    )
                    in
                    case Fase.criar linhasAtualizadas of
                        Ok novaFase ->
                            ( { model
                                | partida =
                                    Jogando
                                        { jogo
                                            | historico =
                                                Historico.avancar novaFase jogo.historico
                                            , ajuda = SemAjuda
                                        }
                              }
                            , Cmd.none
                            )

                        Err _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Verificar ->
            case model.partida of
                Jogando jogo ->
                    ( { model
                        | partida =
                            Jogando { jogo | ajuda = PedindoSolucao }
                      }
                    , Api.verificar
                        (Historico.atual jogo.historico)
                        VerificacaoChegou
                    )

                _ ->
                    ( model, Cmd.none )

        VerificacaoChegou resultado ->
            ( atualizarAjuda
                (\ajuda ->
                    case resultado of
                        Ok resposta ->
                            ResultadoVerificacao
                                resposta.solucoes
                                resposta.minimo

                        Err erro ->
                            ErroAjuda erro
                )
                model
            , Cmd.none
            )

        PassouSobre posicao ->
            ( { model | posicaoEmFoco = posicao }
            , Cmd.none
            )


-- FUNCOES AUXILIARES


reiniciarJogo : Jogo -> Partida
reiniciarJogo jogo =
    Jogando
        { jogo
            | historico = Historico.iniciar jogo.inicial
            , cliques = 0
            , ajuda = SemAjuda
        }


atualizarAjuda : (Ajuda -> Ajuda) -> Model -> Model
atualizarAjuda transformar model =
    case model.partida of
        Jogando jogo ->
            { model
                | partida =
                    Jogando
                        { jogo | ajuda = transformar jogo.ajuda }
            }

        Vencida jogo ->
            { model
                | partida =
                    Vencida
                        { jogo | ajuda = transformar jogo.ajuda }
            }

        _ ->
            model


configurarTabuleiro : Model -> Tabuleiro.Config Msg
configurarTabuleiro model =
    { aoClicar = Clicou
    , aoPassar = PassouSobre
    , posicaoEmFoco = model.posicaoEmFoco
    , dica =
        case model.partida of
            Jogando jogo ->
                posicaoDaDica jogo.ajuda

            Vencida jogo ->
                posicaoDaDica jogo.ajuda

            _ ->
                Nothing
    , bloqueado =
        model.modo == Editar
            || (case model.partida of
                    Gerando ->
                        True

                    _ ->
                        False
               )
    }


posicaoDaDica : Ajuda -> Maybe Fase.Posicao
posicaoDaDica ajuda =
    case ajuda of
        Dica posicao ->
            Just posicao

        _ ->
            Nothing


-- VIEW


view : Model -> Html Msg
view model =
    main_ [ class "app" ]
        [ h1 [ class "app-title" ] [ text "Carimbó" ]
        , viewConteudo model
        ]


viewConteudo : Model -> Html Msg
viewConteudo model =
    case model.partida of
        SemFase ->
            div [ class "app-inicio" ]
                [ p [] [ text "Bem-vindo ao Carimbó!" ]
                , button [ onClick NovaFase ]
                    [ text "Iniciar jogo" ]
                ]

        Gerando ->
            div [ class "app-carregando" ]
                [ p [] [ text "Gerando fase..." ]
                ]

        FalhaAoGerar erro ->
            div [ class "app-erro" ]
                [ p [] [ text ("Não foi possível gerar a fase: " ++ erro) ]
                , button [ onClick NovaFase ]
                    [ text "Tentar novamente" ]
                ]

        Jogando jogo ->
            viewJogo model jogo False

        Vencida jogo ->
            viewJogo model jogo True


viewJogo : Model -> Jogo -> Bool -> Html Msg
viewJogo model jogo venceu =
    let
        faseAtual =
            Historico.atual jogo.historico
    in
    div [ class "app-jogo" ]
        [ div [ class "app-status" ]
            [ h2 []
                [ text
                    (if venceu then
                        "Fase concluída!"

                     else
                        "Sua partida"
                    )
                ]
            , p []
                [ text ("Cliques: " ++ String.fromInt jogo.cliques) ]
            , p []
                [ text ("Mínimo de cliques: " ++ String.fromInt jogo.minimo) ]
            ]

        , Tabuleiro.view
            (configurarTabuleiro model)
            faseAtual

        , viewControles model jogo venceu
        , viewAjuda jogo.ajuda
        ]


viewControles : Model -> Jogo -> Bool -> Html Msg
viewControles model jogo venceu =
    div [ class "app-controles" ]
        [ button
            [ onClick Desfazer
            , disabled (not (Historico.podeDesfazer jogo.historico))
            ]
            [ text "Desfazer" ]

        , button
            [ onClick Refazer
            , disabled
                (venceu || not (Historico.podeRefazer jogo.historico))
            ]
            [ text "Refazer" ]

        , button [ onClick Reiniciar ]
            [ text "Reiniciar" ]

        , button [ onClick PedirDica, disabled venceu ]
            [ text "Pedir dica" ]

        , button [ onClick PedirSolucao, disabled venceu ]
            [ text "Ver solução" ]

        , button [ onClick Verificar, disabled venceu ]
            [ text "Verificar fase" ]

        , button [ onClick NovaFase ]
            [ text "Nova fase" ]

        , button
            [ onClick
                (MudouModo
                    (if model.modo == Jogar then
                        Editar

                     else
                        Jogar
                    )
                )
            ]
            [ text
                (if model.modo == Jogar then
                    "Modo de edição"

                 else
                    "Modo de jogo"
                )
            ]
        ]


viewAjuda : Ajuda -> Html Msg
viewAjuda ajuda =
    div [ class "app-ajuda" ]
        (case ajuda of
            SemAjuda ->
                []

            PedindoDica ->
                [ p [] [ text "Calculando dica..." ] ]

            Dica posicao ->
                [ p []
                    [ text
                        ("Dica: clique na linha "
                            ++ String.fromInt (posicao.linha + 1)
                            ++ ", coluna "
                            ++ String.fromInt (posicao.coluna + 1)
                            ++ "."
                        )
                    ]
                ]

            PedindoSolucao ->
                [ p [] [ text "Calculando solução..." ] ]

            AnimandoSolucao cliques ->
                [ p []
                    [ text
                        ("A solução possui "
                            ++ String.fromInt (List.length cliques)
                            ++ " movimentos."
                        )
                    ]
                ]

            ErroAjuda erro ->
                [ p [] [ text ("Erro: " ++ erro) ] ]

            ResultadoVerificacao solucoes minimo ->
                [ p []
                    [ text
                        ("Quantidade de soluções: "
                            ++ String.fromInt solucoes
                        )
                    ]
                , p []
                    [ text
                        ("Mínimo de cliques: "
                            ++ (case minimo of
                                    Just valor ->
                                        String.fromInt valor

                                    Nothing ->
                                        "Não disponível"
                               )
                        )
                    ]
                ]
        )


-- PROGRAMA PRINCIPAL


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
