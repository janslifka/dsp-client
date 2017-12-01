module KnowledgeModels.Migration.Update exposing (..)

import Auth.Models exposing (Session)
import Common.Types exposing (ActionResult(..))
import Jwt
import KnowledgeModels.Editor.Models.Events exposing (getEventUuid)
import KnowledgeModels.Migration.Models exposing (Model)
import KnowledgeModels.Migration.Msgs exposing (Msg(..))
import KnowledgeModels.Models.Migration exposing (..)
import KnowledgeModels.Requests exposing (getMigration, postMigrationConflict)
import Msgs
import Requests exposing (toCmd)


getMigrationCmd : String -> Session -> Cmd Msgs.Msg
getMigrationCmd uuid session =
    getMigration uuid session
        |> toCmd GetMigrationCompleted Msgs.KnowledgeModelsMigrationMsg


postMigrationConflictCmd : String -> Session -> MigrationResolution -> Cmd Msgs.Msg
postMigrationConflictCmd uuid session resolution =
    resolution
        |> encodeMigrationResolution
        |> postMigrationConflict uuid session
        |> toCmd PostMigrationConflictCompleted Msgs.KnowledgeModelsMigrationMsg


handleGetMigrationCompleted : Model -> Result Jwt.JwtError Migration -> ( Model, Cmd Msgs.Msg )
handleGetMigrationCompleted model result =
    case result of
        Ok migration ->
            ( { model | migration = Success migration }, Cmd.none )

        Err error ->
            ( { model | migration = Error "Unable to get migration" }, Cmd.none )


handleResolveChange : (String -> MigrationResolution) -> Session -> Model -> ( Model, Cmd Msgs.Msg )
handleResolveChange createMigrationResolution session model =
    let
        cmd =
            case model.migration of
                Success migration ->
                    getEventUuid migration.migrationState.targetEvent
                        |> createMigrationResolution
                        |> postMigrationConflictCmd model.branchUuid session

                _ ->
                    Cmd.none
    in
    ( { model | conflict = Loading }, cmd )


handleAcceptChange : Session -> Model -> ( Model, Cmd Msgs.Msg )
handleAcceptChange =
    handleResolveChange newAcceptMigrationResolution


handleRejectChange : Session -> Model -> ( Model, Cmd Msgs.Msg )
handleRejectChange =
    handleResolveChange newRejectMigrationResolution


handlePostMigrationConflictCompleted : Session -> Model -> Result Jwt.JwtError String -> ( Model, Cmd Msgs.Msg )
handlePostMigrationConflictCompleted session model result =
    case result of
        Ok migration ->
            let
                cmd =
                    getMigrationCmd model.branchUuid session
            in
            ( { model | migration = Loading, conflict = Unset }, cmd )

        Err error ->
            ( { model | conflict = Error "Unable to resolve conflict" }, Cmd.none )


update : Msg -> Session -> Model -> ( Model, Cmd Msgs.Msg )
update msg session model =
    case msg of
        GetMigrationCompleted result ->
            handleGetMigrationCompleted model result

        AcceptEvent ->
            handleAcceptChange session model

        RejectEvent ->
            handleRejectChange session model

        PostMigrationConflictCompleted result ->
            handlePostMigrationConflictCompleted session model result

        _ ->
            ( model, Cmd.none )
