module Search exposing (..)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Horizon
import Json.Encode as Encode
import Json.Decode as Json
import Json.Decode.Pipeline as Decode


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


collectionName : String
collectionName =
    "chat"


type alias Model =
    { keyword : String
    , results : Maybe (List Message)
    }


type alias Message =
    { id : String
    , name : String
    , value : String
    }


init : ( Model, Cmd Msg )
init =
    ( { keyword = "", results = Nothing }, Cmd.none )


keywordEncoder : String -> Json.Value
keywordEncoder keyword =
    let
        _ =
            Debug.log "keyword" keyword
    in
        Encode.object [ ( "value", Encode.string keyword ) ]


messageDecoder : Json.Decoder Message
messageDecoder =
    Decode.decode Message
        |> Decode.required "id" Json.string
        |> Decode.required "name" Json.string
        |> Decode.required "value" Json.string



-- MSG


type alias Error =
    String


type Msg
    = Input String
    | Search
    | SearchResponse (Result Error (List (Maybe Message)))



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input keyword ->
            ( { model | keyword = keyword }, Cmd.none )

        Search ->
            ( model, Cmd.none )

        SearchResponse result ->
            let
                _ =
                    Debug.log "results" result
            in
                ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ label []
            [ text "Search: "
            , input
                [ style []
                , onInput Input
                , value model.keyword
                ]
                []
            , button [ onClick Search ] [ text "Search" ]
            , viewResults model
            ]
        ]


viewResults : Model -> Html Msg
viewResults model =
    case model.results of
        Nothing ->
            text ""

        Just results ->
            ul []
                (results
                    |> List.map
                        (\item ->
                            li []
                                [ b [] [ text (item.name ++ ": ") ]
                                , text item.value
                                ]
                        )
                )



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []
