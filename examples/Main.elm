module Main exposing (..)

import Chat
import Search
import Html exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { chat : Chat.Model
    , search : Search.Model
    }


init : ( Model, Cmd Msg )
init =
    let
        ( chatModel, chatCmd ) =
            Chat.init

        ( searchModel, searchCmd ) =
            Search.init
    in
        ( { chat = chatModel
          , search = searchModel
          }
        , Cmd.batch
            [ chatCmd |> Cmd.map ChatMsg
            , searchCmd |> Cmd.map SearchMsg
            ]
        )



-- MSG


type Msg
    = NoOp
    | ChatMsg Chat.Msg
    | SearchMsg Search.Msg



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

        SearchMsg searchMsg ->
            let
                ( searchModel, searchCmd ) =
                    Search.update searchMsg model.search
            in
                ( { model | search = searchModel }, Cmd.map SearchMsg searchCmd )



-- VIEW


view : Model -> Html Msg
view model =
    section []
        [ h1 [] [ text "Elm Horizon Examples" ]
        , section []
            [ h3 [] [ text "Chat App" ]
            , Chat.view model.chat |> Html.map ChatMsg
            ]
        , section []
            [ h3 [] [ text "Search App" ]
            , Search.view model.search |> Html.map SearchMsg
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Chat.subscriptions model.chat |> Sub.map ChatMsg
        , Search.subscriptions model.search |> Sub.map SearchMsg
        ]
