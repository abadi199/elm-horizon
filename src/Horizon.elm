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
        , Modifier(..)
        , Direction(..)
        , Error
        )

import Json.Decode as Json exposing (Decoder)
import Result exposing (Result)
import Json.Encode as Encode


type alias CollectionName =
    String


type alias Id =
    String


type alias Error =
    { errorCode : Int
    , message : String
    , stack : String
    }


unknownError : Error
unknownError =
    { errorCode = -1, message = "Unknown error", stack = "" }


type alias IdResponse =
    { id : Maybe Id, error : Maybe Error }


type alias ValuesResponse =
    { values : Maybe (List Json.Value), error : Maybe Error }


type alias Response =
    { error : Maybe Error }



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


port removeAllPort : ( CollectionName, List Json.Value ) -> Cmd msg


port removeAllSubscription : (Response -> msg) -> Sub msg


port removePort : ( CollectionName, Json.Value ) -> Cmd msg


port removeSubscription : (Response -> msg) -> Sub msg


port updatePort : ( CollectionName, List Json.Value ) -> Cmd msg


port updateSubscription : (Response -> msg) -> Sub msg


port replacePort : ( CollectionName, List Json.Value ) -> Cmd msg


port replaceSubscription : (Response -> msg) -> Sub msg


port watchPort : ( CollectionName, List Json.Value ) -> Cmd msg


port watchSubscription : (ValuesResponse -> msg) -> Sub msg


port fetchPort : ( CollectionName, List Json.Value ) -> Cmd msg


port fetchSubscription : (ValuesResponse -> msg) -> Sub msg



-- ErrorRS


listTagger : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> ValuesResponse -> msg
listTagger decoder tagger response =
    response
        |> .values
        |> Result.fromMaybe (Maybe.withDefault unknownError response.error)
        |> Result.map (List.map (Json.decodeValue decoder >> Result.toMaybe))
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


insertCmd : List Json.Value -> CollectionName -> Cmd msg
insertCmd =
    flippedCurry insertPort


insertSub : (Result Error () -> msg) -> Sub msg
insertSub tagger =
    responseTagger tagger |> insertSubscription


storeCmd : List Json.Value -> CollectionName -> Cmd msg
storeCmd =
    flippedCurry storePort


storeSub : (Result Error () -> msg) -> Sub msg
storeSub tagger =
    responseTagger tagger |> storeSubscription


upsertCmd : List Json.Value -> CollectionName -> Cmd msg
upsertCmd =
    flippedCurry upsertPort


upsertSub : (Result Error () -> msg) -> Sub msg
upsertSub tagger =
    responseTagger tagger |> upsertSubscription


removeAllCmd : List Json.Value -> CollectionName -> Cmd msg
removeAllCmd =
    flippedCurry removeAllPort


removeAllSub : (Result Error () -> msg) -> Sub msg
removeAllSub tagger =
    responseTagger tagger |> removeAllSubscription


removeCmd : Json.Value -> CollectionName -> Cmd msg
removeCmd =
    flippedCurry removePort


removeSub : (Result Error () -> msg) -> Sub msg
removeSub tagger =
    responseTagger tagger |> removeSubscription


updateCmd : List Json.Value -> CollectionName -> Cmd msg
updateCmd =
    flippedCurry updatePort


updateSub : (Result Error () -> msg) -> Sub msg
updateSub tagger =
    responseTagger tagger |> updateSubscription


replaceCmd : List Json.Value -> CollectionName -> Cmd msg
replaceCmd =
    flippedCurry replacePort


replaceSub : (Result Error () -> msg) -> Sub msg
replaceSub tagger =
    responseTagger tagger |> replaceSubscription


type Direction
    = Ascending
    | Descending


type Modifier
    = Above Json.Value
    | Below Json.Value
    | Find (List Json.Value)
    | FindAll Json.Value
    | Limit Int
    | Order String Direction


directionToValue : Direction -> Json.Value
directionToValue direction =
    case direction of
        Ascending ->
            Encode.string "ascending"

        Descending ->
            Encode.string "descending"


toValue : Modifier -> Json.Value
toValue modifier =
    case modifier of
        Above value ->
            Encode.object [ ( "modifier", Encode.string "above" ), ( "value", value ) ]

        Below value ->
            Encode.object [ ( "modifier", Encode.string "below" ), ( "value", value ) ]

        Find values ->
            Encode.object [ ( "modifier", Encode.string "find" ), ( "value", Encode.list values ) ]

        FindAll value ->
            Encode.object [ ( "modifier", Encode.string "findAll" ), ( "value", value ) ]

        Limit number ->
            Encode.object [ ( "modifier", Encode.string "limit" ), ( "value", Encode.int number ) ]

        Order field direction ->
            Encode.object
                [ ( "modifier", Encode.string "order" )
                , ( "value"
                  , Encode.object
                        [ ( "field", Encode.string field )
                        , ( "direction", directionToValue direction )
                        ]
                  )
                ]


watchCmd : List Modifier -> CollectionName -> Cmd msg
watchCmd modifiers collectionName =
    modifiers
        |> List.map toValue
        |> curry watchPort collectionName


watchSub : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> Sub msg
watchSub decoder tagger =
    listTagger decoder tagger |> watchSubscription


fetchCmd : List Modifier -> CollectionName -> Cmd msg
fetchCmd modifiers collectionName =
    modifiers
        |> List.map toValue
        |> curry fetchPort collectionName


fetchSub : Decoder a -> (Result Error (List (Maybe a)) -> msg) -> Sub msg
fetchSub decoder tagger =
    listTagger decoder tagger |> fetchSubscription



-- Utility


flippedCurry =
    flipTuple >> curry


flipTuple : (( a, b ) -> c) -> ( b, a ) -> c
flipTuple f ( b, a ) =
    f ( a, b )
