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
    { name : String
    , input : Message
    , messages : List Message
    }


type alias Message =
    { name : String
    , value : String
    }


init : ( Model, Cmd Msg )
init =
    ( { name = "", input = { name = "", value = "" }, messages = [] }, Cmd.none )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage (List Message)
    | UpdateName String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "update" msg of
        Input newInput ->
            ( { model | input = { name = model.name, value = newInput } }, Cmd.none )

        Send ->
            ( { model | input = { name = model.name, value = "" } }, send model.input )

        NewMessage msgs ->
            ( { model | messages = msgs }, Cmd.none )

        UpdateName newName ->
            ( { model | name = newName }, Cmd.none )



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
        [ input [ placeholder "username", onInput UpdateName, value model.name ] []
        , if model.name == "" then
            text ""
          else
            (input
                [ onInput Input
                , value model.input.value
                , onEnter Send
                ]
                []
            )
        , button [ onClick Send ] [ text "Send" ]
        , div [] (List.map viewMessage (List.reverse model.messages))
        ]


onEnter : Msg -> Attribute Msg
onEnter message =
    let
        filterKey =
            (\keyCode ->
                if keyCode /= 13 then
                    Err "enter"
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
    div [] [ text <| msg.name ++ ":" ++ msg.value ]
