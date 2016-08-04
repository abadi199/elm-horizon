port module Horizon
    exposing
        ( storeCmd
        , storeSub
        , watchCmd
        , watchSub
        , fetchCmd
        , fetchSub
        , removeAllCmd
        , removeAllSub
        , StoreResponse
        )

import Json.Decode as Json exposing (Decoder)
import Task exposing (Task)


type alias CollectionName =
    String


type alias Id =
    String


type alias Error =
    String


type alias StoreResponse =
    { id : Maybe Id, error : Maybe String }



-- MSG


type Msg
    = Next (List Json.Value)



-- PORTS


port storePort : ( CollectionName, Json.Value ) -> Cmd msg


port storeSubscription : (StoreResponse -> msg) -> Sub msg


port watchPort : CollectionName -> Cmd msg


port watchSubscription : (List Json.Value -> msg) -> Sub msg


port fetchPort : CollectionName -> Cmd msg


port fetchSubscription : (List Json.Value -> msg) -> Sub msg


port removeAllPort : ( CollectionName, List Json.Value ) -> Cmd msg


port removeAllSubscription : (Json.Value -> msg) -> Sub msg



-- HELPERS


decodeList : Decoder a -> (List (Maybe a) -> msg) -> List Json.Value -> msg
decodeList decoder tagger values =
    values
        |> List.map (Json.decodeValue decoder >> Result.toMaybe)
        |> tagger


decode : Decoder a -> (Task String a -> msg) -> Json.Value -> msg
decode decoder tagger value =
    value |> Json.decodeValue decoder |> Task.fromResult |> tagger



-- HORIZON API


storeCmd : CollectionName -> Json.Value -> Cmd msg
storeCmd collectionName value =
    curry storePort collectionName value


storeSub : (Task Error Id -> msg) -> Sub msg
storeSub tagger =
    storeSubscription
        (\response ->
            response.id
                |> Task.fromMaybe (Maybe.withDefault "Unknown error" response.error)
                |> tagger
        )


watchCmd : CollectionName -> Cmd msg
watchCmd =
    watchPort


watchSub : Decoder a -> (List (Maybe a) -> msg) -> Sub msg
watchSub decoder tagger =
    decodeList decoder tagger |> watchSubscription


fetchCmd : CollectionName -> Cmd msg
fetchCmd =
    fetchPort


fetchSub : Decoder a -> (List (Maybe a) -> msg) -> Sub msg
fetchSub decoder tagger =
    decodeList decoder tagger |> fetchSubscription


removeAllCmd : CollectionName -> List Json.Value -> Cmd msg
removeAllCmd collectionName ids =
    curry removeAllPort collectionName ids


removeAllSub : Decoder a -> (Task String a -> msg) -> Sub msg
removeAllSub decoder tagger =
    decode decoder tagger |> removeAllSubscription



-- Collection.subscribe
-- Collection.above
-- Collection.below
-- Collection.find
-- Collection.findAll
-- Collection.limit
-- Collection.order
-- Collection.remove
-- Collection.insert
-- Collection.replace
-- Collection.update
-- Collection.upsert
