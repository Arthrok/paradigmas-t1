module MainTest exposing (suite)

import Editor exposing (Ferramenta(..))
import Expect
import Fase exposing (Celula(..), Forma(..), Luz(..))
import Html.Attributes as Attributes
import Main exposing (Ajuda(..), Modo(..), Msg(..), Partida(..))
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Main"
        [ describe "pedido de dica (#17)"
            [ test "o botão emite PedirDica durante a partida" <|
                \_ ->
                    comFase faseAUmClique
                        |> Main.view
                        |> Query.fromHtml
                        |> Query.find [ Selector.class "botao-dica" ]
                        |> Event.simulate Event.click
                        |> Event.expect PedirDica
            , test "pede dica a partir de uma fase já alterada" <|
                \_ ->
                    let
                        model =
                            comFase faseDeDoisCliques
                                |> atualizar (Clicou centro)
                                |> atualizar PedirDica
                    in
                    case faseDeDoisCliques of
                        Ok fase ->
                            Expect.all
                                [ \_ ->
                                    model.partida
                                        |> ajudaDe
                                        |> Expect.equal (Just PedindoDica)
                                , \_ ->
                                    faseAtual model
                                        |> Expect.equal (Just (Fase.apertar centro fase))
                                ]
                                ()

                        Err erro ->
                            Expect.fail erro
            , test "o botão fica desabilitado enquanto pede dica" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar PedirDica
                        |> Main.view
                        |> Query.fromHtml
                        |> Query.find [ Selector.class "botao-dica" ]
                        |> Query.has [ Selector.disabled True ]
            , test "pedido repetido mantém o estado enquanto aguarda resposta" <|
                \_ ->
                    let
                        model =
                            comFase faseAUmClique
                                |> atualizar PedirDica
                    in
                    atualizar PedirDica model
                        |> Expect.equal model
            , test "resposta destaca somente a célula sugerida até o próximo clique" <|
                \_ ->
                    let
                        comDica =
                            comFase faseDeDoisCliques
                                |> atualizar PedirDica
                                |> atualizar (DicaChegou 1 (Ok centro))
                    in
                    Expect.all
                        [ \_ ->
                            Main.view comDica
                                |> Query.fromHtml
                                |> Query.find [ Selector.id "celula-1-1" ]
                                |> Query.has [ Selector.class "tabuleiro-celula--dica" ]
                        , \_ ->
                            comDica |> esperarDestaques 1
                        , \_ ->
                            comDica
                                |> atualizar (Clicou centro)
                                |> esperarDestaques 0
                        ]
                        ()
            , test "resposta atrasada após um clique não restaura a dica" <|
                \_ ->
                    let
                        model =
                            comFase faseDeDoisCliques
                                |> atualizar PedirDica
                                |> atualizar (Clicou centro)
                                |> atualizar (DicaChegou 1 (Ok centro))
                    in
                    Expect.all
                        [ \_ -> ajudaDe model.partida |> Expect.equal (Just SemAjuda)
                        , \_ -> esperarDestaques 0 model
                        ]
                        ()
            , test "resposta antiga não substitui o pedido mais recente" <|
                \_ ->
                    let
                        aguardando =
                            comFase faseDeDoisCliques
                                |> atualizar PedirDica
                                |> atualizar (Clicou centro)
                                |> atualizar PedirDica

                        comRespostaAntiga =
                            atualizar (DicaChegou 1 (Ok centro)) aguardando
                    in
                    Expect.all
                        [ \_ ->
                            comRespostaAntiga.partida
                                |> ajudaDe
                                |> Expect.equal (Just PedindoDica)
                        , \_ ->
                            comRespostaAntiga
                                |> atualizar (DicaChegou 2 (Ok canto))
                                |> .partida
                                |> ajudaDe
                                |> Expect.equal (Just (Dica canto))
                        ]
                        ()
            , test "erro 422 sem solução aparece como aviso e sem destaque" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar PedirDica
                        |> atualizar (DicaChegou 1 (Err "Esta fase não tem solução."))
                        |> esperarErroDaDica "Esta fase não tem solução."
            , test "erro 422 de fase resolvida aparece como aviso e sem destaque" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar PedirDica
                        |> atualizar (DicaChegou 1 (Err "A fase já está resolvida."))
                        |> esperarErroDaDica "A fase já está resolvida."
            , test "seguir dicas até apagar todas as luzes leva à vitória" <|
                \_ ->
                    comFase faseDeDoisCliques
                        |> atualizar PedirDica
                        |> atualizar (DicaChegou 1 (Ok centro))
                        |> atualizar (Clicou centro)
                        |> atualizar PedirDica
                        |> atualizar (DicaChegou 2 (Ok canto))
                        |> atualizar (Clicou canto)
                        |> .partida
                        |> ehVencida
                        |> Expect.equal True
            ]
        , describe "vitória (#18)"
            [ test "mensagem mostra cliques e mínimo" <|
                \_ ->
                    Main.mensagemVitoria 5 3
                        |> Expect.equal "Você fez em 5 cliques, o mínimo era 3."
            , test "mensagem elogia quando atinge o mínimo" <|
                \_ ->
                    Main.mensagemVitoria 1 1
                        |> Expect.equal "Você fez em 1 clique, o mínimo era 1. Perfeito!"
            , test "clicar na última jogada leva a Vencida" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (Clicou centro)
                        |> .partida
                        |> ehVencida
                        |> Expect.equal True
            ]
        , describe "animação da solução (#18)"
            [ test "SolucaoChegou inicia a animação" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (SolucaoChegou (Ok { cliques = [ centro ], minimo = 1 }))
                        |> .partida
                        |> ajudaDe
                        |> Expect.equal (Just (AnimandoSolucao [ centro ]))
            , test "cada passo aplica um clique e consome a lista" <|
                \_ ->
                    comFase faseDeDoisCliques
                        |> atualizar (SolucaoChegou (Ok { cliques = [ centro, canto ], minimo = 2 }))
                        |> atualizar PassoAnimacao
                        |> .partida
                        |> (\p -> ( ajudaDe p, cliquesDe p ))
                        |> Expect.equal ( Just (AnimandoSolucao [ canto ]), Just 1 )
            , test "o último passo resolve a fase" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (SolucaoChegou (Ok { cliques = [ centro ], minimo = 1 }))
                        |> atualizar PassoAnimacao
                        |> .partida
                        |> ehVencida
                        |> Expect.equal True
            , test "clique do jogador é ignorado durante a animação" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (SolucaoChegou (Ok { cliques = [ centro ], minimo = 1 }))
                        |> atualizar (Clicou centro)
                        |> .partida
                        |> cliquesDe
                        |> Expect.equal (Just 0)
            , test "passo sem animação não faz nada" <|
                \_ ->
                    let
                        m =
                            comFase faseAUmClique
                    in
                    atualizar PassoAnimacao m
                        |> Expect.equal m
            ]
        , describe "editor (#20)"
            [ test "editar altera a fase com a ferramenta escolhida" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (MudouModo Editar)
                        |> atualizar (EscolheuFerramenta (Carimbar Bloco))
                        |> atualizar (AplicouFerramenta centro)
                        |> celulaEm centro
                        |> Expect.equal (Just (Ativa Bloco Acesa))
            , test "criar fase partindo da tela inicial usa fase em branco" <|
                \_ ->
                    inicial
                        |> atualizar (MudouModo Editar)
                        |> (\m -> ( m.modo, m.partida |> ehJogando ))
                        |> Expect.equal ( Editar, True )
            , test "clicar no modo jogar não edita" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (AplicouFerramenta centro)
                        |> celulaEm centro
                        |> Expect.equal (Just (Ativa Cruz Acesa))
            , test "verificar com solução permite jogar a fase" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (MudouModo Editar)
                        |> atualizar (VerificacaoChegou (Ok { solucoes = 2, minimo = Just 1 }))
                        |> atualizar JogarFase
                        |> (\m -> ( m.modo, minimoDe m.partida ))
                        |> Expect.equal ( Jogar, Just 1 )
            , test "sem solução não dá para jogar" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (MudouModo Editar)
                        |> atualizar (VerificacaoChegou (Ok { solucoes = 0, minimo = Nothing }))
                        |> atualizar JogarFase
                        |> .modo
                        |> Expect.equal Editar
            , test "editar depois de verificar descarta o resultado" <|
                \_ ->
                    comFase faseAUmClique
                        |> atualizar (MudouModo Editar)
                        |> atualizar (VerificacaoChegou (Ok { solucoes = 2, minimo = Just 1 }))
                        |> atualizar (AplicouFerramenta centro)
                        |> .partida
                        |> ajudaDe
                        |> Expect.equal (Just SemAjuda)
            ]
        ]



-- AUXILIARES


centro : Fase.Posicao
centro =
    { linha = 1, coluna = 1 }


canto : Fase.Posicao
canto =
    { linha = 3, coluna = 3 }


inicial : Main.Model
inicial =
    Main.init () |> Tuple.first


atualizar : Msg -> Main.Model -> Main.Model
atualizar msg model =
    Main.update msg model |> Tuple.first


{-| 4x4 de cruzes: só a vizinhança do centro está acesa, 1 clique resolve.
-}
faseAUmClique : Result String Fase.Fase
faseAUmClique =
    montar [ ( 1, 1 ), ( 0, 1 ), ( 2, 1 ), ( 1, 0 ), ( 1, 2 ) ]


{-| Dois cliques independentes (centro e canto) resolvem.
-}
faseDeDoisCliques : Result String Fase.Fase
faseDeDoisCliques =
    montar [ ( 1, 1 ), ( 0, 1 ), ( 2, 1 ), ( 1, 0 ), ( 1, 2 ), ( 3, 3 ), ( 2, 3 ), ( 3, 2 ) ]


montar : List ( Int, Int ) -> Result String Fase.Fase
montar acesas =
    List.range 0 3
        |> List.map
            (\l ->
                List.range 0 3
                    |> List.map
                        (\c ->
                            Ativa Cruz
                                (if List.member ( l, c ) acesas then
                                    Acesa

                                 else
                                    Apagada
                                )
                        )
            )
        |> Fase.criar


comFase : Result String Fase.Fase -> Main.Model
comFase resultado =
    case resultado of
        Ok fase ->
            inicial
                |> atualizar (FaseGerada (Ok { fase = fase, minimo = 1 }))

        Err erro ->
            inicial
                |> atualizar (FaseGerada (Err erro))


ajudaDe : Partida -> Maybe Ajuda
ajudaDe partida =
    case partida of
        Jogando jogo ->
            Just jogo.ajuda

        Vencida jogo ->
            Just jogo.ajuda

        _ ->
            Nothing


cliquesDe : Partida -> Maybe Int
cliquesDe partida =
    case partida of
        Jogando jogo ->
            Just jogo.cliques

        Vencida jogo ->
            Just jogo.cliques

        _ ->
            Nothing


minimoDe : Partida -> Maybe Int
minimoDe partida =
    case partida of
        Jogando jogo ->
            Just jogo.minimo

        _ ->
            Nothing


ehVencida : Partida -> Bool
ehVencida partida =
    case partida of
        Vencida _ ->
            True

        _ ->
            False


ehJogando : Partida -> Bool
ehJogando partida =
    case partida of
        Jogando _ ->
            True

        _ ->
            False


celulaEm : Fase.Posicao -> Main.Model -> Maybe Celula
celulaEm posicao model =
    case model.partida of
        Jogando jogo ->
            Fase.celula posicao (Main.faseDoJogo jogo)

        _ ->
            Nothing


faseAtual : Main.Model -> Maybe Fase.Fase
faseAtual model =
    case model.partida of
        Jogando jogo ->
            Just (Main.faseDoJogo jogo)

        _ ->
            Nothing


esperarDestaques : Int -> Main.Model -> Expect.Expectation
esperarDestaques quantidade model =
    Main.view model
        |> Query.fromHtml
        |> Query.findAll [ Selector.class "tabuleiro-celula--dica" ]
        |> Query.count (Expect.equal quantidade)


esperarErroDaDica : String -> Main.Model -> Expect.Expectation
esperarErroDaDica mensagem model =
    Expect.all
        [ \_ ->
            Main.view model
                |> Query.fromHtml
                |> Query.find [ Selector.attribute (Attributes.attribute "role" "alert") ]
                |> Query.has [ Selector.text mensagem ]
        , \_ -> esperarDestaques 0 model
        ]
        ()
