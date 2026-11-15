module Main exposing (main)

{-| Página provisória: o jogo de verdade (Model, Msg, update, view) chega
na issue #15. Ver docs/design-elm.md.
-}

import Html exposing (Html, h1, main_, p, text)
import Html.Attributes exposing (class)


main : Html msg
main =
    main_ [ class "app" ]
        [ h1 [ class "app-title" ] [ text "Carimbó" ]
        , p [] [ text "Em construção." ]
        ]
