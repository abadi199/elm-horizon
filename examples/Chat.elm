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
    { id : Id
    , name : String
    , value : String
    , mode : MessageMode
    }


type MessageMode
    = ViewMode
    | EditMode


messageDecoder : Json.Decoder Message
messageDecoder =
    Decode.decode Message
        |> Decode.required "id" Json.string
        |> Decode.required "name" Json.string
        |> Decode.required "value" Json.string
        |> Decode.hardcoded ViewMode


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
      , input = { id = "", name = "", value = "", mode = ViewMode }
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
    | DeleteMessage Id
    | DeleteMessageResponse (Result Error ())
    | Edit Id


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | input = { id = "", name = model.name, value = newInput, mode = ViewMode } }, Cmd.none )

        Send ->
            ( model
            , Horizon.storeCmd collectionName (messageEncoder model.input)
            )

        SendResponse result ->
            case result of
                Err error ->
                    ( { model | error = Just error }
                    , Cmd.none
                    )

                _ ->
                    ( { model | input = { id = "", name = model.name, value = "", mode = ViewMode } }
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
            case result of
                Err error ->
                    ( { model | error = Just error }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DeleteMessage id ->
            ( model
            , Horizon.removeCmd collectionName (Encode.string id)
            )

        DeleteMessageResponse result ->
            case result of
                Err error ->
                    ( { model | error = Just error }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Edit id ->
            ( updateMessageMode id EditMode model, Cmd.none )


updateMessageMode : Id -> MessageMode -> Model -> Model
updateMessageMode id mode model =
    let
        _ =
            Debug.log "updateMessageMode" id

        maybeUpdate =
            model.messages
                |> List.filter (\message -> message.id == id)
                |> List.head
                |> Maybe.map (\message -> { message | mode = mode })
    in
        case maybeUpdate of
            Nothing ->
                model

            Just updatedMessage ->
                { model
                    | messages =
                        model.messages
                            |> List.map
                                (\message ->
                                    if message.id == id then
                                        updatedMessage
                                    else
                                        message
                                )
                }



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
                , div [] (model.messages |> List.reverse |> List.map (viewMessage model))
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


viewMessage : Model -> Message -> Html Msg
viewMessage model msg =
    case msg.mode of
        ViewMode ->
            div [ style [ ( "margin", "5px 0" ) ] ]
                [ b [] [ text <| msg.name ++ ": " ]
                , text msg.value
                , if model.name == msg.name then
                    (div [ style [ ( "float", "right" ) ] ]
                        [ button [ style [ ( "padding", "0 4px" ) ], onClick (Edit msg.id) ] [ text "Edit" ]
                        , button [ style [ ( "padding", "0 4px" ) ], onClick (DeleteMessage msg.id) ] [ text "Delete" ]
                        ]
                    )
                  else
                    text ""
                ]

        EditMode ->
            div [ style [ ( "margin", "5px 0" ) ] ]
                [ b [] [ text <| msg.name ++ ": " ]
                , input [ value msg.value ] []
                , div [ style [ ( "float", "right" ) ] ]
                    [ button [ style [ ( "padding", "0 4px" ) ] ] [ text "Cancel" ]
                    , button [ style [ ( "padding", "0 4px" ) ] ] [ text "Submit" ]
                    ]
                ]


viewError : Maybe Error -> Html msg
viewError maybeError =
    maybeError
        |> Maybe.map (\error -> p [ style [ ( "color", "red" ) ] ] [ text error ])
        |> Maybe.withDefault (text "")
