module Historico exposing
    ( Historico
    , atual
    , avancar
    , desfazer
    , iniciar
    , podeDesfazer
    , podeRefazer
    , refazer
    )


type Historico a
    = Historico
        { passado : List a
        , atual : a
        , futuro : List a
        }


iniciar : a -> Historico a
iniciar valor =
    Historico
        { passado = []
        , atual = valor
        , futuro = []
        }


avancar : a -> Historico a -> Historico a
avancar novo (Historico historico) =
    Historico
        { passado = historico.atual :: historico.passado
        , atual = novo
        , futuro = []
        }


desfazer : Historico a -> Historico a
desfazer (Historico historico) =
    case historico.passado of
        anterior :: restantes ->
            Historico
                { passado = restantes
                , atual = anterior
                , futuro = historico.atual :: historico.futuro
                }

        [] ->
            Historico historico


refazer : Historico a -> Historico a
refazer (Historico historico) =
    case historico.futuro of
        proximo :: restantes ->
            Historico
                { passado = historico.atual :: historico.passado
                , atual = proximo
                , futuro = restantes
                }

        [] ->
            Historico historico


atual : Historico a -> a
atual (Historico historico) =
    historico.atual


podeDesfazer : Historico a -> Bool
podeDesfazer (Historico historico) =
    not (List.isEmpty historico.passado)


podeRefazer : Historico a -> Bool
podeRefazer (Historico historico) =
    not (List.isEmpty historico.futuro)
