port module Horizon exposing (..)

import Json.Decode as Json exposing (Decoder)


type alias Collection =
    String



-- MSG


type Msg
    = Next (List Json.Value)



-- PORTS


port storePort : { collection : Collection, value : Json.Value } -> Cmd msg


port watchPort : Collection -> Cmd msg


port nextPort : (List Json.Value -> msg) -> Sub msg



-- HORIZON API


store : Collection -> Json.Value -> Cmd msg
store collection value =
    storePort { collection = collection, value = value }


watch : Collection -> Cmd msg
watch =
    watchPort


next : Decoder a -> (List (Maybe a) -> msg) -> Sub msg
next decoder tagger =
    decode decoder tagger |> nextPort


decode : Decoder a -> (List (Maybe a) -> msg) -> List Json.Value -> msg
decode decoder tagger values =
    values
        |> List.map (Json.decodeValue decoder >> Result.toMaybe)
        |> tagger
