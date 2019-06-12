module KMEditor.Publish.View exposing (view)

import Common.Form exposing (CustomFormError)
import Common.Html.Attribute exposing (wideDetailClass)
import Common.View.ActionButton as ActionButton
import Common.View.FormActions as FormActions
import Common.View.FormExtra as FormExtra
import Common.View.FormGroup as FormGroup
import Common.View.FormResult as FormResult
import Common.View.Page as Page
import Form exposing (Form)
import Form.Field exposing (Field, FieldValue(..))
import Form.Input as Input
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import KMEditor.Common.Models exposing (KnowledgeModelDetail, kmLastVersion)
import KMEditor.Publish.Models exposing (Model, PublishForm)
import KMEditor.Publish.Msgs exposing (Msg(..))
import KMEditor.Routing exposing (Route(..))
import KnowledgeModels.Common.Version as Version exposing (Version)
import Routing exposing (Route(..))
import Utils exposing (flip)


view : Model -> Html Msg
view model =
    Page.actionResultView (contentView model) model.knowledgeModel


contentView : Model -> KnowledgeModelDetail -> Html Msg
contentView model knowledgeModel =
    div [ wideDetailClass "KMEditor__Publish" ]
        [ Page.header "Publish new version" []
        , div []
            [ FormResult.view model.publishingKnowledgeModel
            , formView model.form knowledgeModel
            , FormActions.view
                (KMEditor IndexRoute)
                (ActionButton.ButtonConfig "Publish" model.publishingKnowledgeModel (FormMsg Form.Submit) False)
            ]
        ]


formView : Form CustomFormError PublishForm -> KnowledgeModelDetail -> Html Msg
formView form knowledgeModel =
    let
        mbVersion =
            kmLastVersion knowledgeModel
    in
    div []
        [ Html.map FormMsg <| FormGroup.textView knowledgeModel.name "Knowledge Model"
        , Html.map FormMsg <| FormGroup.codeView knowledgeModel.kmId "Knowledge Model ID"
        , lastVersion mbVersion
        , versionInputGroup form mbVersion
        , Html.map FormMsg <| FormGroup.input form "description" "Description"
        , FormExtra.textAfter "Short description of the Knowledge Model."
        , Html.map FormMsg <| FormGroup.markdownEditor form "readme" "Readme"
        , FormExtra.textAfter "Describe the Knowledge Model, you can use Markdown."
        ]


lastVersion : Maybe Version -> Html msg
lastVersion mbVersion =
    mbVersion
        |> Maybe.map Version.toString
        |> Maybe.withDefault "No version of this package has been published yet."
        |> flip FormGroup.textView "Last version"


versionInputGroup : Form CustomFormError PublishForm -> Maybe Version -> Html Msg
versionInputGroup form mbVersion =
    let
        majorField =
            Form.getFieldAsString "major" form

        minorField =
            Form.getFieldAsString "minor" form

        patchField =
            Form.getFieldAsString "patch" form

        errorClass =
            case ( majorField.liveError, minorField.liveError, patchField.liveError ) of
                ( Nothing, Nothing, Nothing ) ->
                    ""

                _ ->
                    " is-invalid"

        nextMajor =
            mbVersion
                |> Maybe.map Version.nextMajor
                |> Maybe.withDefault (Version.create 1 0 0)

        nextMinor =
            mbVersion
                |> Maybe.map Version.nextMinor
                |> Maybe.withDefault (Version.create 0 1 0)

        nextPatch =
            mbVersion
                |> Maybe.map Version.nextPatch
                |> Maybe.withDefault (Version.create 0 0 1)
    in
    div [ class "form-group" ]
        [ label [ class "control-label" ] [ text "New version" ]
        , div [ class "version-inputs" ]
            [ Html.map FormMsg <| Input.baseInput "number" String Form.Text majorField [ class <| "form-control" ++ errorClass, Html.Attributes.min "0" ]
            , text "."
            , Html.map FormMsg <| Input.baseInput "number" String Form.Text minorField [ class <| "form-control" ++ errorClass, Html.Attributes.min "0" ]
            , text "."
            , Html.map FormMsg <| Input.baseInput "number" String Form.Text patchField [ class <| "form-control" ++ errorClass, Html.Attributes.min "0" ]
            ]
        , p [ class "form-text text-muted version-suggestions" ]
            [ text "Suggestions: "
            , a [ onClick <| FormSetVersion nextMajor ] [ text <| Version.toString nextMajor ]
            , a [ onClick <| FormSetVersion nextMinor ] [ text <| Version.toString nextMinor ]
            , a [ onClick <| FormSetVersion nextPatch ] [ text <| Version.toString nextPatch ]
            ]
        , FormExtra.text "Version number is in format X.Y.Z. Increasing number Z indicates only some fixes, number Y minor changes and number X indicate major change."
        ]
