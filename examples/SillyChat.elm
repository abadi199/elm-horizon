module SillyChat exposing (main)

import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Html.App
import Html exposing (Html, text)
import Horizon exposing (watchCmd, insertCmd, watchSub, insertSub, Error, Modifier(..))


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { messages : List (Maybe ChatMessage) }


view : Model -> Html msg
view model =
    text <| toString model


type alias ChatMessage =
    { from : String
    , msg : String
    }


type Msg
    = NewChatMessage (Result Error (List (Maybe ChatMessage)))
    | InsertResponse (Result Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewChatMessage result ->
            let
                _ =
                    Debug.log "NewChatMessage" result
            in
                case result of
                    Ok chatMessages ->
                        ( { model | messages = chatMessages }, Cmd.none )

                    Err error ->
                        ( model, Cmd.none )

        InsertResponse result ->
            let
                _ =
                    Debug.log "InsertResponse" result
            in
                ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ watchSub chatMessageDecoder NewChatMessage
        , insertSub InsertResponse
        ]


init : ( Model, Cmd Msg )
init =
    ( { messages = [] }
    , Cmd.batch
        [ watchCmd "chat_messages"
            [ FindAll <| [ encode { from = "elmo" } ]
            , Limit 5
            ]
        , insertCmd "chat_messages" [ encodeChatMessage { from = "elmo", msg = "Hello World!" } ]
        , insertCmd "chat_messages" [ encodeChatMessage { from = "elmo", msg = "From Elm Conference" } ]
        , insertCmd "chat_messages" [ encodeChatMessage { from = "abadi", msg = "Just ignore me!" } ]
        ]
    )


encode : { from : String } -> Encode.Value
encode from =
    Encode.object
        [ ( "from", Encode.string from.from ) ]


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage message =
    Encode.object
        [ ( "from", Encode.string message.from )
        , ( "msg", Encode.string message.msg )
        ]


chatMessageDecoder : Decode.Decoder ChatMessage
chatMessageDecoder =
    Decode.decode ChatMessage
        |> Decode.required "from" Decode.string
        |> Decode.required "msg" Decode.string
