module Chat exposing (..)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode as Encode
import Horizon exposing (Modifier(..), Direction(..))
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
    , draft : String
    , mode : MessageMode
    }


emptyMessage : Message
emptyMessage =
    { id = "", name = "", value = "", draft = "", mode = ViewMode }


type MessageMode
    = ViewMode
    | EditMode


messageDecoder : Json.Decoder Message
messageDecoder =
    Decode.decode Message
        |> Decode.required "id" Json.string
        |> Decode.required "name" Json.string
        |> Decode.required "value" Json.string
        |> Decode.hardcoded ""
        |> Decode.hardcoded ViewMode


newMessageEncoder : Message -> Json.Value
newMessageEncoder message =
    Encode.object
        [ ( "name", Encode.string message.name )
        , ( "value", Encode.string message.value )
        ]


messageEncoder : Message -> Json.Value
messageEncoder message =
    Encode.object
        [ ( "id", Encode.string message.id )
        , ( "name", Encode.string message.name )
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
      , input = emptyMessage
      , messages = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Input String
    | Send
    | SendResponse (Result Error ())
    | NewMessage (Result Error (List (Maybe Message)))
    | UpdateName String
    | EnterChat
    | DeleteAll
    | DeleteAllResponse (Result Error ())
    | DeleteMessage Id
    | DeleteMessageResponse (Result Error ())
    | Edit Id
    | UpdateDraft Id String
    | CancelEdit Id
    | Update Id
    | UpdateResponse (Result Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | input = { emptyMessage | name = model.name, value = newInput } }, Cmd.none )

        Send ->
            ( model
            , Horizon.insertCmd collectionName (newMessageEncoder model.input |> toList)
            )

        SendResponse result ->
            case result of
                Err error ->
                    ( { model | error = Just error }
                    , Cmd.none
                    )

                _ ->
                    ( { model | input = { emptyMessage | name = model.name } }
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
            ( { model | state = Chat }
            , Horizon.watchCmd collectionName []
            )

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
            ( updateMessageMode EditMode id model, Cmd.none )

        UpdateDraft id draft ->
            ( updateMessageDraft draft id model, Cmd.none )

        CancelEdit id ->
            ( updateMessageMode ViewMode id model, Cmd.none )

        Update id ->
            let
                updater message =
                    { message | value = message.draft, draft = "", mode = ViewMode }

                maybeMessage =
                    findMessage id model
                        |> Maybe.map updater
            in
                ( updateMessageMode ViewMode id model
                , maybeMessage
                    |> Maybe.map (messageEncoder >> toList >> Horizon.updateCmd collectionName)
                    |> Maybe.withDefault Cmd.none
                )

        UpdateResponse result ->
            case result of
                Err error ->
                    ( { model | error = Just error }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


toList : a -> List a
toList =
    flip (::) []


findMessage : Id -> Model -> Maybe Message
findMessage id model =
    model.messages
        |> List.filter (\message -> message.id == id)
        |> List.head


updateMessageDraft : String -> Id -> Model -> Model
updateMessageDraft draft =
    updateMessage (\message -> { message | draft = draft })


updateMessageMode : MessageMode -> Id -> Model -> Model
updateMessageMode mode =
    let
        updateDraft message =
            case mode of
                ViewMode ->
                    { message | draft = "" }

                EditMode ->
                    { message | draft = message.value }
    in
        updateMessage
            (\message ->
                { message | mode = mode }
                    |> updateDraft
            )


updateMessage : (Message -> Message) -> Id -> Model -> Model
updateMessage updater id model =
    let
        maybeUpdate =
            model.messages
                |> List.filter (\message -> message.id == id)
                |> List.head
                |> Maybe.map updater
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
                , div [] (model.messages |> List.map (viewMessage model))
                , p []
                    [ (textarea
                        [ onInput Input
                        , value model.input.value
                        , onEnter Send
                        , style [ ( "width", "100%" ), ( "height", "50px" ) ]
                        ]
                        []
                      )
                    , button [ onClick DeleteAll ] [ text "Delete All" ]
                    , button [ onClick Send ] [ text "Send" ]
                    ]
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
                [ textarea
                    [ value msg.draft
                    , style [ ( "width", "100%" ) ]
                    , onInput (UpdateDraft msg.id)
                    ]
                    []
                , div []
                    [ button
                        [ style [ ( "padding", "0 4px" ) ]
                        , onClick (CancelEdit msg.id)
                        ]
                        [ text "Cancel" ]
                    , button
                        [ style [ ( "padding", "0 4px" ) ]
                        , onClick (Update msg.id)
                        ]
                        [ text "Submit" ]
                    ]
                ]


viewError : Maybe Error -> Html msg
viewError maybeError =
    maybeError
        |> Maybe.map (\error -> p [ style [ ( "color", "red" ) ] ] [ text error ])
        |> Maybe.withDefault (text "")



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Horizon.watchSub messageDecoder NewMessage
        , Horizon.insertSub SendResponse
        , Horizon.removeAllSub DeleteAllResponse
        , Horizon.updateSub UpdateResponse
        ]
