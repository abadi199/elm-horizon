module Chat exposing (..)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode
import Horizon
import Json.Decode.Pipeline as Decode
import Result exposing (Result)


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


type alias Error =
    String


type alias Id =
    String


type alias Model =
    { state : ChatState
    , error : Maybe Error
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
      , error = Nothing
      , name = ""
      , input = { id = "", name = "", value = "" }
      , messages = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Input String
    | Send
    | SendResponse (Result Error Id)
    | NewMessage (Result Error (List (Maybe Message)))
    | UpdateName String
    | EnterChat
    | DeleteAll
    | DeleteAllResponse (Result Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | input = { id = "", name = model.name, value = newInput } }, Cmd.none )

        Send ->
            ( model
            , Horizon.storeCmd collectionName (messageEncoder model.input)
            )

        SendResponse result ->
            let
                _ =
                    Debug.log "SendResponse" result
            in
                case result of
                    Err error ->
                        ( { model | error = Just error }
                        , Cmd.none
                        )

                    _ ->
                        ( { model | input = { id = "", name = model.name, value = "" } }
                        , Cmd.none
                        )

        NewMessage result ->
            case result of
                Result.Err error ->
                    ( { model | error = Just error }, Cmd.none )

                Ok messages ->
                    ( { model
                        | messages =
                            messages
                                |> List.filterMap identity
                      }
                    , Cmd.none
                    )

        UpdateName newName ->
            ( { model | name = newName }, Cmd.none )

        EnterChat ->
            ( { model | state = Chat }, Horizon.watchCmd collectionName )

        DeleteAll ->
            ( model
            , model.messages
                |> List.map messageIdEncoder
                |> Horizon.removeAllCmd collectionName
            )

        DeleteAllResponse result ->
            case Debug.log "DeleteAllResponse" result of
                Err error ->
                    ( { model | error = Just error }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


findMyMessages : Model -> List Message
findMyMessages model =
    model.messages
        |> List.filter (\message -> message.name == model.name)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Horizon.watchSub messageDecoder NewMessage
        , Horizon.storeSub SendResponse
        , Horizon.removeAllSub DeleteAllResponse
        ]



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
                [ viewError model.error
                , p [] [ text <| "Logged in as: " ++ model.name ]
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


viewError : Maybe Error -> Html msg
viewError maybeError =
    maybeError
        |> Maybe.map (\error -> p [ style [ ( "color", "red" ) ] ] [ text error ])
        |> Maybe.withDefault (text "")
