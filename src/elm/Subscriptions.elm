module Subscriptions exposing (subscriptions)

import Common.Menu.Subscriptions
import KMEditor.Subscriptions
import Models exposing (Model)
import Msgs exposing (Msg(..))
import Routes


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        currentViewSubscriptions =
            case model.appState.route of
                Routes.KMEditorRoute route ->
                    KMEditor.Subscriptions.subscriptions KMEditorMsg route model.kmEditorModel

                _ ->
                    Sub.none

        menuSubscriptions =
            Common.Menu.Subscriptions.subscriptions model.menuModel
    in
    Sub.batch [ currentViewSubscriptions, menuSubscriptions ]
