module Fase exposing
    ( Fase, Celula(..), Forma(..), Luz(..), Posicao
    , tamanhoMinimo, tamanhoMaximo, criar, linhas, tamanho, celula, luz
    , apertar, afetadas, resolvida
    )

{-| O domínio do jogo: os tipos e a regra do clique.

Este módulo não conhece `Html` nem `Http`. Tudo aqui é puro: as mesmas
entradas sempre dão as mesmas saídas, e nada é alterado no lugar.

O clique é aplicado aqui, no Elm, para a resposta ser instantânea. O
raciocínio (dica, solução, gerador) fica no Prolog. A regra de quem afeta
quem existe nas duas linguagens e precisa ser a MESMA: a tabela de
`deslocamentos` abaixo é cópia da tabela de `backend/prolog/regras.pl`
(ver docs/adr/0006-clique-aplicado-no-elm.md).


# Tipos

@docs Fase, Celula, Forma, Luz, Posicao


# Criar e consultar

@docs tamanhoMinimo, tamanhoMaximo, criar, linhas, tamanho, celula, luz


# Regra do clique

@docs apertar, afetadas, resolvida

-}

-- TIPOS


type Luz
    = Acesa
    | Apagada


{-| O desenho de efeito de uma célula clicável.
-}
type Forma
    = Cruz
    | Xis
    | Linha
    | Coluna
    | Bloco


{-| Uma célula travada não pode ser clicada, então não tem forma.

Com este tipo, "célula travada com carimbo" é impossível de representar:
não existe valor de `Celula` que signifique isso.

-}
type Celula
    = Ativa Forma Luz
    | Travada Luz


type alias Posicao =
    { linha : Int
    , coluna : Int
    }


{-| Tipo OPACO: o construtor `Fase` não é exportado. O único jeito de obter
uma `Fase` de fora deste módulo é por `criar`, que confere o formato. Assim,
toda `Fase` que existe no programa é quadrada e tem um tamanho permitido.
-}
type Fase
    = Fase (List (List Celula))


tamanhoMinimo : Int
tamanhoMinimo =
    4


tamanhoMaximo : Int
tamanhoMaximo =
    6



-- CRIAR E CONSULTAR


criar : List (List Celula) -> Result String Fase
criar celulas =
    let
        n =
            List.length celulas
    in
    if n < tamanhoMinimo || n > tamanhoMaximo then
        Err
            ("O tabuleiro deve ter de "
                ++ String.fromInt tamanhoMinimo
                ++ " a "
                ++ String.fromInt tamanhoMaximo
                ++ " linhas."
            )

    else if List.any (\fileira -> List.length fileira /= n) celulas then
        Err "O tabuleiro precisa ser quadrado."

    else
        Ok (Fase celulas)


linhas : Fase -> List (List Celula)
linhas (Fase celulas) =
    celulas


tamanho : Fase -> Int
tamanho (Fase celulas) =
    List.length celulas


celula : Posicao -> Fase -> Maybe Celula
celula posicao fase =
    if dentro fase posicao then
        linhas fase
            |> List.drop posicao.linha
            |> List.head
            |> Maybe.andThen (List.drop posicao.coluna >> List.head)

    else
        Nothing


luz : Celula -> Luz
luz c =
    case c of
        Ativa _ l ->
            l

        Travada l ->
            l



-- REGRA DO CLIQUE


{-| As células que uma forma inverte, relativas à célula clicada, como
pares (linha, coluna). Mesma tabela de `deslocamentos/2` em regras.pl.
-}
deslocamentos : Forma -> List ( Int, Int )
deslocamentos forma =
    case forma of
        Cruz ->
            [ ( 0, 0 ), ( -1, 0 ), ( 1, 0 ), ( 0, -1 ), ( 0, 1 ) ]

        Xis ->
            [ ( 0, 0 ), ( -1, -1 ), ( -1, 1 ), ( 1, -1 ), ( 1, 1 ) ]

        Linha ->
            [ ( 0, 0 ), ( 0, -1 ), ( 0, 1 ), ( 0, -2 ), ( 0, 2 ) ]

        Coluna ->
            [ ( 0, 0 ), ( -1, 0 ), ( 1, 0 ), ( -2, 0 ), ( 2, 0 ) ]

        Bloco ->
            [ ( -1, -1 )
            , ( -1, 0 )
            , ( -1, 1 )
            , ( 0, -1 )
            , ( 0, 0 )
            , ( 0, 1 )
            , ( 1, -1 )
            , ( 1, 0 )
            , ( 1, 1 )
            ]


{-| As posições que um clique em `posicao` inverte. Vazio se a célula é
travada ou está fora do tabuleiro. Útil também para a view pré-visualizar o
efeito de um clique.
-}
afetadas : Posicao -> Fase -> List Posicao
afetadas posicao fase =
    case celula posicao fase of
        Just (Ativa forma _) ->
            deslocamentos forma
                |> List.map
                    (\( dLinha, dColuna ) ->
                        { linha = posicao.linha + dLinha
                        , coluna = posicao.coluna + dColuna
                        }
                    )
                |> List.filter (dentro fase)

        _ ->
            []


{-| A fase depois de um clique. Clicar numa célula travada ou fora do
tabuleiro não muda nada.
-}
apertar : Posicao -> Fase -> Fase
apertar posicao fase =
    let
        alvos =
            afetadas posicao fase

        inverterSeAfetada l c cel =
            if List.member { linha = l, coluna = c } alvos then
                inverter cel

            else
                cel
    in
    Fase (List.indexedMap (\l fileira -> List.indexedMap (inverterSeAfetada l) fileira) (linhas fase))


resolvida : Fase -> Bool
resolvida fase =
    linhas fase
        |> List.concat
        |> List.all (\c -> luz c == Apagada)



-- AUXILIARES


inverter : Celula -> Celula
inverter c =
    case c of
        Ativa forma l ->
            Ativa forma (inverterLuz l)

        Travada l ->
            Travada (inverterLuz l)


inverterLuz : Luz -> Luz
inverterLuz l =
    case l of
        Acesa ->
            Apagada

        Apagada ->
            Acesa


dentro : Fase -> Posicao -> Bool
dentro fase { linha, coluna } =
    let
        n =
            tamanho fase
    in
    linha >= 0 && linha < n && coluna >= 0 && coluna < n
