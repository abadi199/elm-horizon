port module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { input : Message
    , messages : List Message
    }


type alias Message =
    { value : String }


init : ( Model, Cmd Msg )
init =
    ( Model { value = "" } [], Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage (List Message)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { input, messages } =
    case Debug.log "update" msg of
        Input newInput ->
            ( Model { value = newInput } messages, Cmd.none )

        Send ->
            ( Model { value = "" } messages, send input )

        NewMessage msgs ->
            ( Model input msgs, Cmd.none )



-- PORTS


port send : Message -> Cmd msg


port newMessage : (List Message -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    newMessage NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input
            [ onInput Input
            , value model.input.value
            , onEnter Send
            ]
            []
        , button [ onClick Send ] [ text "Send" ]
        , div [] (List.map viewMessage (List.reverse model.messages))
        ]


onEnter : Msg -> Attribute Msg
onEnter message =
    let
        filterKey =
            (\keyCode ->
                if (Debug.log "" keyCode) == 10 then
                    Err "numeric"
                else
                    Ok keyCode
            )

        decoder =
            filterKey
                |> Json.customDecoder keyCode
                |> Json.map (\_ -> message)
    in
        on "keyup" decoder


viewMessage : Message -> Html msg
viewMessage msg =
    div [] [ text msg.value ]
