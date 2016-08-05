port module Horizon
    exposing
        ( insertCmd
        , insertSub
        , storeCmd
        , storeSub
        , upsertCmd
        , upsertSub
        , watchCmd
        , watchSub
        , fetchCmd
        , fetchSub
        , removeAllCmd
        , removeAllSub
        , removeCmd
        , removeSub
        , updateCmd
        , updateSub
        , replaceCmd
        , replaceSub
        )

import Json.Decode as Json exposing (Decoder)
import Result exposing (Result)


type alias CollectionName =
    String


type alias Id =
    String


type alias Error =
    String


type alias IdResponse =
    { id : Maybe Id, error : Maybe String }


type alias ListResponse =
    { values : Maybe (List Json.Value), error : Maybe String }


type alias Response =
    { error : Maybe String }



-- MSG


type Msg
    = Next (List Json.Value)



-- PORTS


port insertPort : ( CollectionName, List Json.Value ) -> Cmd msg


port insertSubscription : (Response -> msg) -> Sub msg


port storePort : ( CollectionName, List Json.Value ) -> Cmd msg


port storeSubscription : (Response -> msg) -> Sub msg


port upsertPort : ( CollectionName, List Json.Value ) -> Cmd msg


port upsertSubscription : (Response -> msg) -> Sub msg


port watchPort : CollectionName -> Cmd msg


port watchSubscription : (ListResponse -> msg) -> Sub msg


port fetchPort : CollectionName -> Cmd msg


port fetchSubscription : (ListResponse -> msg) -> Sub msg


port removeAllPort : ( CollectionName, List Json.Value ) -> Cmd msg


port removeAllSubscription : (Response -> msg) -> Sub msg


port removePort : ( CollectionName, Json.Value ) -> Cmd msg


port removeSubscription : (Response -> msg) -> Sub msg


port updatePort : ( CollectionName, List Json.Value ) -> Cmd msg


port updateSubscription : (Response -> msg) -> Sub msg


port replacePort : ( CollectionName, List Json.Value ) -> Cmd msg


port replaceSubscription : (Response -> msg) -> Sub msg



-- HELPERS


listTagger : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> ListResponse -> msg
listTagger decoder tagger response =
    response
        |> .values
        |> Result.fromMaybe (Maybe.withDefault "Unknown error" response.error)
        |> Result.map (List.map (Json.decodeValue decoder >> Result.toMaybe))
        |> tagger


valueTagger : Decoder a -> (Result Error a -> msg) -> Json.Value -> msg
valueTagger decoder tagger value =
    value
        |> Json.decodeValue decoder
        |> tagger


responseTagger : (Result Error () -> msg) -> Response -> msg
responseTagger tagger response =
    let
        result =
            case response.error of
                Nothing ->
                    Result.Ok ()

                Just error ->
                    Result.Err error
    in
        tagger result



-- HORIZON API


insertCmd : CollectionName -> List Json.Value -> Cmd msg
insertCmd =
    curry insertPort


insertSub : (Result Error () -> msg) -> Sub msg
insertSub tagger =
    responseTagger tagger |> insertSubscription


storeCmd : CollectionName -> List Json.Value -> Cmd msg
storeCmd =
    curry storePort


storeSub : (Result Error () -> msg) -> Sub msg
storeSub tagger =
    responseTagger tagger |> storeSubscription


upsertCmd : CollectionName -> List Json.Value -> Cmd msg
upsertCmd =
    curry upsertPort


upsertSub : (Result Error () -> msg) -> Sub msg
upsertSub tagger =
    responseTagger tagger |> upsertSubscription


watchCmd : CollectionName -> Cmd msg
watchCmd =
    watchPort


watchSub : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> Sub msg
watchSub decoder tagger =
    listTagger decoder tagger |> watchSubscription


fetchCmd : CollectionName -> Cmd msg
fetchCmd =
    fetchPort


fetchSub : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> Sub msg
fetchSub decoder tagger =
    listTagger decoder tagger |> fetchSubscription


removeAllCmd : CollectionName -> List Json.Value -> Cmd msg
removeAllCmd =
    curry removeAllPort


removeAllSub : (Result Error () -> msg) -> Sub msg
removeAllSub tagger =
    responseTagger tagger |> removeAllSubscription


removeCmd : CollectionName -> Json.Value -> Cmd msg
removeCmd =
    curry removePort


removeSub : (Result Error () -> msg) -> Sub msg
removeSub tagger =
    responseTagger tagger |> removeSubscription


updateCmd : CollectionName -> List Json.Value -> Cmd msg
updateCmd =
    curry updatePort


updateSub : (Result Error () -> msg) -> Sub msg
updateSub tagger =
    responseTagger tagger |> updateSubscription


replaceCmd : CollectionName -> List Json.Value -> Cmd msg
replaceCmd =
    curry replacePort


replaceSub : (Result Error () -> msg) -> Sub msg
replaceSub tagger =
    responseTagger tagger |> replaceSubscription


type Modifier
    = Above
    | Below
    | Find
    | FindAll
    | Limit
    | Order
