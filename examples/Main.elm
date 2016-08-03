module Main exposing (..)

import Chat
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { chat : Chat.Model }


init : ( Model, Cmd Msg )
init =
    let
        ( chatModel, chatCmd ) =
            Chat.init
    in
        ( { chat = chatModel }, Cmd.batch [ chatCmd |> Cmd.map ChatMsg ] )



-- MSG


type Msg
    = NoOp
    | ChatMsg Chat.Msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChatMsg chatMsg ->
            let
                ( chatModel, chatCmd ) =
                    Chat.update chatMsg model.chat
            in
                ( { model | chat = chatModel }, Cmd.map ChatMsg chatCmd )



-- VIEW


view : Model -> Html Msg
view model =
    section []
        [ h1 [] [ text "Elm Horizon Examples" ]
        , section []
            [ h3 [] [ text "Chat App" ]
            , Chat.view model.chat |> Html.App.map ChatMsg
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Chat.subscriptions model.chat |> Sub.map ChatMsg
        ]
