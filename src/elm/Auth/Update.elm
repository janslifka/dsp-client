module Auth.Update exposing (update)

import Auth.Models as AuthModel exposing (initialSession, parseJwt, setToken, setUser)
import Auth.Msgs as AuthMsgs
import Auth.Requests exposing (..)
import Browser.Navigation exposing (Key)
import Common.Models exposing (getServerErrorJwt)
import Jwt
import Models exposing (Model, setJwt, setSession)
import Msgs exposing (Msg)
import Ports
import Public.Login.Msgs
import Public.Msgs
import Requests exposing (toCmd)
import Routing exposing (Route(..), cmdNavigate, homeRoute)
import Users.Common.Models exposing (User)
import Utils exposing (dispatch)


update : AuthMsgs.Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthMsgs.Token token jwt ->
            let
                state =
                    model.state

                newModel =
                    model
                        |> setSession (setToken model.state.session token)
                        |> setJwt (Just jwt)
            in
            ( newModel, getCurrentUserCmd newModel )

        AuthMsgs.GetCurrentUserCompleted result ->
            getCurrentUserCompleted model result

        AuthMsgs.Logout ->
            logout model


getCurrentUserCmd : Model -> Cmd Msg
getCurrentUserCmd model =
    getCurrentUser model.state.session
        |> toCmd AuthMsgs.GetCurrentUserCompleted Msgs.AuthMsg


getCurrentUserCompleted : Model -> Result Jwt.JwtError User -> ( Model, Cmd Msg )
getCurrentUserCompleted model result =
    case result of
        Ok user ->
            let
                session =
                    setUser model.state.session user
            in
            ( setSession session model
            , Cmd.batch
                [ Ports.storeSession <| Just session
                , cmdNavigate model.state.key Welcome
                ]
            )

        Err error ->
            let
                msg =
                    getServerErrorJwt error "Loading profile info failed"
                        |> Public.Login.Msgs.GetProfileInfoFailed
                        |> Public.Msgs.LoginMsg
                        |> Msgs.PublicMsg
            in
            ( model, dispatch msg )


logout : Model -> ( Model, Cmd Msg )
logout model =
    let
        cmd =
            Cmd.batch [ Ports.clearSession (), cmdNavigate model.state.key homeRoute ]
    in
    ( setSession initialSession model, cmd )
