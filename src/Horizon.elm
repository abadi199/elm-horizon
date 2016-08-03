port module Horizon
    exposing
        ( storeCmd
        , watchCmd
        , watchSub
        , fetchCmd
        , fetchSub
        , removeAllCmd
        )

import Json.Decode as Json exposing (Decoder)


type alias CollectionName =
    String



-- MSG


type Msg
    = Next (List Json.Value)



-- PORTS


port storePort : ( CollectionName, Json.Value ) -> Cmd msg


port watchPort : CollectionName -> Cmd msg


port watchSubscription : (List Json.Value -> msg) -> Sub msg


port fetchPort : CollectionName -> Cmd msg


port fetchSubscription : (List Json.Value -> msg) -> Sub msg


port removeAllPort : ( CollectionName, List Json.Value ) -> Cmd msg



-- HELPERS


decode : Decoder a -> (List (Maybe a) -> msg) -> List Json.Value -> msg
decode decoder tagger values =
    values
        |> List.map (Json.decodeValue decoder >> Result.toMaybe)
        |> tagger



-- HORIZON API


storeCmd : CollectionName -> Json.Value -> Cmd msg
storeCmd collectionName value =
    curry storePort collectionName value


watchCmd : CollectionName -> Cmd msg
watchCmd =
    watchPort


watchSub : Decoder a -> (List (Maybe a) -> msg) -> Sub msg
watchSub decoder tagger =
    decode decoder tagger |> watchSubscription


fetchCmd : CollectionName -> Cmd msg
fetchCmd =
    fetchPort


fetchSub : Decoder a -> (List (Maybe a) -> msg) -> Sub msg
fetchSub decoder tagger =
    decode decoder tagger |> fetchSubscription


removeAllCmd : CollectionName -> List Json.Value -> Cmd msg
removeAllCmd collectionName ids =
    curry removeAllPort collectionName ids



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
