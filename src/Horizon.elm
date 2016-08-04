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
        , removeCmd
        , removeSub
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


port storePort : ( CollectionName, Json.Value ) -> Cmd msg


port storeSubscription : (IdResponse -> msg) -> Sub msg


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


storeCmd : CollectionName -> Json.Value -> Cmd msg
storeCmd collectionName value =
    curry storePort collectionName value


storeSub : (Result Error Id -> msg) -> Sub msg
storeSub tagger =
    storeSubscription
        (\response ->
            response.id
                |> Result.fromMaybe (Maybe.withDefault "Unknown error" response.error)
                |> tagger
        )


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
removeAllCmd collectionName ids =
    curry removeAllPort collectionName ids


removeAllSub : (Result Error () -> msg) -> Sub msg
removeAllSub tagger =
    responseTagger tagger |> removeAllSubscription


removeCmd : CollectionName -> Json.Value -> Cmd msg
removeCmd collectionName id =
    curry removePort collectionName id


removeSub : (Result Error () -> msg) -> Sub msg
removeSub tagger =
    responseTagger tagger |> removeSubscription


updateCmd : CollectionName -> List Json.Value -> Cmd msg
updateCmd collectionName values =
    curry updatePort collectionName values



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
