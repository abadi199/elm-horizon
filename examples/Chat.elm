module Chat exposing (..)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode
import Horizon
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
    { state : ChatState
    , name : String
    , input : Message
    , messages : List Message
    }


type ChatState
    = EnterName
    | Chat


type alias Message =
    { id : String
    , name : String
    , value : String
    }


messageDecoder : Json.Decoder Message
messageDecoder =
    Decode.decode Message
        |> Decode.required "id" Json.string
        |> Decode.required "name" Json.string
        |> Decode.required "value" Json.string


messageEncoder : Message -> Json.Value
messageEncoder message =
    Encode.object
        [ ( "name", Encode.string message.name )
        , ( "value", Encode.string message.value )
        ]


messageIdEncoder : Message -> Json.Value
messageIdEncoder message =
    Encode.string message.id


init : ( Model, Cmd Msg )
init =
    ( { state = EnterName
      , name = ""
      , input = { id = "", name = "", value = "" }
      , messages = []
      }
    , Horizon.watchCmd collectionName
    )



-- UPDATE


type Msg
    = Input String
    | Send
    | NewMessage (List (Maybe Message))
    | UpdateName String
    | EnterChat
    | DeleteAll


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | input = { id = "", name = model.name, value = newInput } }, Cmd.none )

        Send ->
            ( { model | input = { id = "", name = model.name, value = "" } }
            , Horizon.storeCmd collectionName (messageEncoder model.input)
            )

        NewMessage msgs ->
            ( { model
                | messages =
                    msgs
                        |> List.filterMap identity
              }
            , Cmd.none
            )

        UpdateName newName ->
            ( { model | name = newName }, Cmd.none )

        EnterChat ->
            ( { model | state = Chat }, Cmd.none )

        DeleteAll ->
            ( { model | messages = [] }
            , findMyMessages model
                |> List.map messageIdEncoder
                |> Horizon.removeAllCmd collectionName
            )


findMyMessages : Model -> List Message
findMyMessages model =
    model.messages
        |> List.filter (\message -> message.name == model.name)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Horizon.watchSub messageDecoder NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    case model.state of
        EnterName ->
            p []
                [ label []
                    [ text "Please enter your name: "
                    , input
                        [ placeholder "username"
                        , onInput UpdateName
                        , onEnter EnterChat
                        , value model.name
                        ]
                        []
                    ]
                , button [ onClick EnterChat ] [ text "Enter Chat" ]
                ]

        Chat ->
            div []
                [ p [] [ text <| "Logged in as: " ++ model.name ]
                , p []
                    [ (input
                        [ onInput Input
                        , value model.input.value
                        , onEnter Send
                        ]
                        []
                      )
                    , button [ onClick Send ] [ text "Send" ]
                    ]
                , div [] (List.map viewMessage (List.reverse model.messages))
                , p [] [ button [ onClick DeleteAll ] [ text "Delete All" ] ]
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
    div [] [ b [] [ text <| msg.name ++ ": " ], text msg.value ]
