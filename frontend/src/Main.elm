module Main exposing (Ajuda(..), Jogo, Model, Modo(..), Msg(..), Partida(..), faseDoJogo, init, main, mensagemVitoria, update)

import Api
import Browser
import Editor exposing (Ferramenta(..))
import Fase
import Historico
import Html exposing (Html, button, div, h1, h2, main_, p, text)
import Html.Attributes exposing (attribute, class, disabled)
import Html.Events exposing (onClick)
import Time
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
    , ferramenta : Ferramenta
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
    | Verificando
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
    | SolucaoChegou (Result String { cliques : List Fase.Posicao, minimo : Int })
    | PassoAnimacao
    | MudouModo Modo
    | EscolheuFerramenta Ferramenta
    | AplicouFerramenta Fase.Posicao
    | JogarFase
    | Verificar
    | VerificacaoChegou (Result String { solucoes : Int, minimo : Maybe Int })
    | PassouSobre (Maybe Fase.Posicao)



-- INICIALIZACAO


init : () -> ( Model, Cmd Msg )
init _ =
    ( { config = configInicial
      , partida = SemFase
      , modo = Jogar
      , posicaoEmFoco = Nothing
      , ferramenta = AlternarLuz
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
                    case ( estaAnimando jogo, Fase.celula posicao (Historico.atual jogo.historico) ) of
                        ( False, Just (Fase.Ativa _ _) ) ->
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
            case ( model.partida, model.modo ) of
                ( Jogando jogo, Jogar ) ->
                    case jogo.ajuda of
                        AnimandoSolucao (posicao :: resto) ->
                            let
                                novaFase =
                                    Fase.apertar posicao (Historico.atual jogo.historico)

                                novoJogo =
                                    { jogo
                                        | historico = Historico.avancar novaFase jogo.historico
                                        , cliques = jogo.cliques + 1
                                        , ajuda =
                                            if List.isEmpty resto then
                                                SemAjuda

                                            else
                                                AnimandoSolucao resto
                                    }
                            in
                            ( { model
                                | partida =
                                    if Fase.resolvida novaFase then
                                        Vencida { novoJogo | ajuda = SemAjuda }

                                    else
                                        Jogando novoJogo
                                , posicaoEmFoco = Nothing
                              }
                            , Cmd.none
                            )

                        AnimandoSolucao [] ->
                            ( { model | partida = Jogando { jogo | ajuda = SemAjuda } }
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        MudouModo novoModo ->
            mudarModo novoModo model

        EscolheuFerramenta ferramenta ->
            ( { model | ferramenta = ferramenta }, Cmd.none )

        AplicouFerramenta posicao ->
            case ( model.modo, model.partida ) of
                ( Editar, Jogando jogo ) ->
                    case Editor.aplicar model.ferramenta posicao (Historico.atual jogo.historico) of
                        Ok novaFase ->
                            ( { model | partida = Jogando (jogoDaFase novaFase 0) }
                            , Cmd.none
                            )

                        Err _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Verificar ->
            case model.partida of
                Jogando jogo ->
                    ( { model | partida = Jogando { jogo | ajuda = Verificando } }
                    , Api.verificar
                        (Historico.atual jogo.historico)
                        VerificacaoChegou
                    )

                _ ->
                    ( model, Cmd.none )

        JogarFase ->
            case ( model.partida, ultimaVerificacao model.partida ) of
                ( Jogando jogo, Just minimo ) ->
                    ( { model
                        | modo = Jogar
                        , partida = Jogando (jogoDaFase (Historico.atual jogo.historico) minimo)
                        , posicaoEmFoco = Nothing
                      }
                    , Cmd.none
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


estaAnimando : Jogo -> Bool
estaAnimando jogo =
    case jogo.ajuda of
        AnimandoSolucao _ ->
            True

        _ ->
            False


jogoDaFase : Fase.Fase -> Int -> Jogo
jogoDaFase fase minimo =
    { historico = Historico.iniciar fase
    , inicial = fase
    , cliques = 0
    , minimo = minimo
    , ajuda = SemAjuda
    }


{-| Mínimo da última verificação, se a fase tem solução.
-}
ultimaVerificacao : Partida -> Maybe Int
ultimaVerificacao partida =
    case partida of
        Jogando { ajuda } ->
            case ajuda of
                ResultadoVerificacao solucoes minimo ->
                    Editor.podeJogar solucoes minimo

                _ ->
                    Nothing

        _ ->
            Nothing


mudarModo : Modo -> Model -> ( Model, Cmd Msg )
mudarModo novoModo model =
    let
        semFoco m =
            { m | modo = novoModo, posicaoEmFoco = Nothing }
    in
    case ( novoModo, model.partida ) of
        ( Editar, Jogando jogo ) ->
            ( semFoco { model | partida = Jogando { jogo | ajuda = SemAjuda } }, Cmd.none )

        ( Editar, Vencida jogo ) ->
            ( semFoco { model | partida = Jogando { jogo | ajuda = SemAjuda } }, Cmd.none )

        ( Editar, _ ) ->
            case Editor.emBranco model.config.tamanho of
                Ok fase ->
                    ( semFoco { model | partida = Jogando (jogoDaFase fase 0) }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ( Jogar, Jogando jogo ) ->
            ( semFoco { model | partida = Jogando { jogo | ajuda = SemAjuda } }, Cmd.none )

        _ ->
            ( semFoco model, Cmd.none )


{-| Texto da tela de vitória.
-}
mensagemVitoria : Int -> Int -> String
mensagemVitoria cliques minimo =
    "Você fez em "
        ++ String.fromInt cliques
        ++ (if cliques == 1 then
                " clique"

            else
                " cliques"
           )
        ++ ", o mínimo era "
        ++ String.fromInt minimo
        ++ (if cliques <= minimo then
                ". Perfeito!"

            else
                "."
           )


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
    { aoClicar =
        if model.modo == Editar then
            AplicouFerramenta

        else
            Clicou
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
        case model.partida of
            Gerando ->
                True

            Jogando jogo ->
                estaAnimando jogo

            _ ->
                False
    , editor = model.modo == Editar
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
                [ p [ class "app-inicio-texto" ] [ text "Bem-vindo ao Carimbó!" ]
                , div [ class "app-controles" ]
                    [ button [ class "controle-botao botao-principal", onClick NovaFase ]
                        [ text "Iniciar jogo" ]
                    , button [ class "controle-botao botao-edicao", onClick (MudouModo Editar) ]
                        [ text "Criar fase" ]
                    ]
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

        editando =
            model.modo == Editar
    in
    div [ class "app-jogo" ]
        [ div [ class "app-status" ]
            (if editando then
                [ h2 [] [ text "Editor de fases" ]
                , p [] [ text "Escolha uma ferramenta e clique nas células." ]
                ]

             else
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
            )
        , Tabuleiro.view
            (configurarTabuleiro model)
            faseAtual
        , if editando then
            viewEditor model

          else
            viewControles model jogo venceu
        , if venceu && not editando then
            viewVitoria jogo

          else
            text ""
        , viewAjuda jogo.ajuda
        ]


viewVitoria : Jogo -> Html Msg
viewVitoria jogo =
    div [ class "app-vitoria", attribute "role" "status" ]
        [ p [ class "app-vitoria-texto" ] [ text (mensagemVitoria jogo.cliques jogo.minimo) ]
        , button
            [ class "controle-botao botao-principal"
            , onClick NovaFase
            ]
            [ text "Nova fase" ]
        ]


viewEditor : Model -> Html Msg
viewEditor model =
    let
        ferramenta rotulo valor =
            button
                [ class
                    ("controle-botao botao-secundario"
                        ++ (if model.ferramenta == valor then
                                " ferramenta-ativa"

                            else
                                ""
                           )
                    )
                , attribute "aria-pressed"
                    (if model.ferramenta == valor then
                        "true"

                     else
                        "false"
                    )
                , onClick (EscolheuFerramenta valor)
                ]
                [ text rotulo ]
    in
    div [ class "app-controles app-editor" ]
        [ ferramenta "Alternar luz" AlternarLuz
        , ferramenta "✚ Cruz" (Carimbar Fase.Cruz)
        , ferramenta "✖ Xis" (Carimbar Fase.Xis)
        , ferramenta "━ Linha" (Carimbar Fase.Linha)
        , ferramenta "┃ Coluna" (Carimbar Fase.Coluna)
        , ferramenta "▣ Bloco" (Carimbar Fase.Bloco)
        , ferramenta "🔒 Trava" Travar
        , button
            [ class "controle-botao botao-verificar"
            , onClick Verificar
            ]
            [ text "Verificar" ]
        , button
            [ class "controle-botao botao-principal"
            , onClick JogarFase
            , disabled (ultimaVerificacao model.partida == Nothing)
            ]
            [ text "Jogar esta fase" ]
        , button
            [ class "controle-botao botao-edicao"
            , onClick (MudouModo Jogar)
            ]
            [ text "Modo de jogo" ]
        ]


viewControles : Model -> Jogo -> Bool -> Html Msg
viewControles model jogo venceu =
    let
        ocupado =
            estaAnimando jogo
    in
    div [ class "app-controles" ]
        [ button
            [ class "controle-botao botao-secundario"
            , onClick Desfazer
            , disabled (ocupado || not (Historico.podeDesfazer jogo.historico))
            ]
            [ text "Desfazer" ]
        , button
            [ class "controle-botao botao-secundario"
            , onClick Refazer
            , disabled
                (ocupado || venceu || not (Historico.podeRefazer jogo.historico))
            ]
            [ text "Refazer" ]
        , button
            [ class "controle-botao botao-perigo"
            , onClick Reiniciar
            , disabled ocupado
            ]
            [ text "Reiniciar" ]
        , button
            [ class "controle-botao botao-dica"
            , onClick PedirDica
            , disabled (ocupado || venceu)
            ]
            [ text "Pedir dica" ]
        , button
            [ class "controle-botao botao-solucao"
            , onClick PedirSolucao
            , disabled (ocupado || venceu)
            ]
            [ text "Mostrar solução" ]
        , button
            [ class "controle-botao botao-principal"
            , onClick NovaFase
            ]
            [ text "Nova fase" ]
        , button
            [ class "controle-botao botao-edicao"
            , onClick (MudouModo Editar)
            ]
            [ text "Modo de edição" ]
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

            Verificando ->
                [ p [] [ text "Verificando fase..." ] ]

            AnimandoSolucao cliques ->
                [ p []
                    [ text
                        (case List.length cliques of
                            1 ->
                                "Mostrando a solução: falta 1 passo."

                            n ->
                                "Mostrando a solução: faltam " ++ String.fromInt n ++ " passos."
                        )
                    ]
                ]

            ErroAjuda erro ->
                [ p [] [ text ("Erro: " ++ erro) ] ]

            ResultadoVerificacao solucoes minimo ->
                [ p []
                    [ text
                        (case minimo of
                            Just valor ->
                                String.fromInt solucoes
                                    ++ (if solucoes == 1 then
                                            " solução"

                                        else
                                            " soluções"
                                       )
                                    ++ ", mínimo "
                                    ++ String.fromInt valor

                            Nothing ->
                                "Sem solução"
                        )
                    ]
                ]
        )



-- PROGRAMA PRINCIPAL


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.partida of
        Jogando jogo ->
            if estaAnimando jogo then
                Time.every 700 (\_ -> PassoAnimacao)

            else
                Sub.none

        _ ->
            Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


faseDoJogo : Jogo -> Fase.Fase
faseDoJogo jogo =
    Historico.atual jogo.historico
