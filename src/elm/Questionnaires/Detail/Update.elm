module Questionnaires.Detail.Update exposing (..)

import Auth.Models exposing (Session)
import Common.Types exposing (ActionResult(..))
import Dict exposing (Dict)
import FormEngine.Model exposing (..)
import FormEngine.Msgs
import FormEngine.Update exposing (updateForm)
import Json.Encode as Encode exposing (..)
import Jwt
import KnowledgeModels.Editor.Models.Entities exposing (Answer, AnswerItemTemplate, AnswerItemTemplateQuestions(..), Chapter, FollowUps(..), Question)
import Msgs
import Questionnaires.Common.Models exposing (QuestionnaireDetail)
import Questionnaires.Detail.Models exposing (Model)
import Questionnaires.Detail.Msgs exposing (Msg(..))
import Questionnaires.Requests exposing (getQuestionnaire, putValues)
import Questionnaires.Routing exposing (Route(Index))
import Routing exposing (cmdNavigate)


fetchData : (Msg -> Msgs.Msg) -> Session -> String -> Cmd Msgs.Msg
fetchData wrapMsg session uuid =
    getQuestionnaire uuid session
        |> Jwt.send GetQuestionnaireCompleted
        |> Cmd.map wrapMsg


update : Msg -> (Msg -> Msgs.Msg) -> Session -> Model -> ( Model, Cmd Msgs.Msg )
update msg wrapMsg session model =
    case msg of
        GetQuestionnaireCompleted result ->
            ( handleGetQuestionnaireCompleted model result, Cmd.none )

        SetActiveChapter chapter ->
            ( handleSetActiveChapter chapter model, Cmd.none )

        FormMsg msg ->
            ( handleFormMsg msg model, Cmd.none )

        Save ->
            handleSave wrapMsg session model

        PutValuesCompleted result ->
            handlePutValuesCompleted model result



{- Update handlers -}


handleGetQuestionnaireCompleted : Model -> Result Jwt.JwtError QuestionnaireDetail -> Model
handleGetQuestionnaireCompleted model result =
    let
        newModel =
            case result of
                Ok questionnaireDetail ->
                    { model
                        | questionnaire = Success questionnaireDetail
                        , activeChapter = List.head questionnaireDetail.knowledgeModel.chapters
                        , values = questionnaireDetail.values
                    }

                Err error ->
                    { model | questionnaire = Error "Unable to get questionnaire." }
    in
    setActiveChapterForm newModel


handleSetActiveChapter : Chapter -> Model -> Model
handleSetActiveChapter chapter model =
    model
        |> updateValues
        |> setActiveChapter chapter
        |> setActiveChapterForm


handleFormMsg : FormEngine.Msgs.Msg -> Model -> Model
handleFormMsg msg model =
    case model.activeChapterForm of
        Just form ->
            { model | activeChapterForm = Just <| updateForm msg form }

        _ ->
            model


handleSave : (Msg -> Msgs.Msg) -> Session -> Model -> ( Model, Cmd Msgs.Msg )
handleSave wrapMsg session model =
    let
        newModel =
            updateValues model

        cmd =
            putValuesCmd wrapMsg session newModel
    in
    ( { newModel | savingQuestionnaire = Loading }, cmd )


handlePutValuesCompleted : Model -> Result Jwt.JwtError String -> ( Model, Cmd Msgs.Msg )
handlePutValuesCompleted model result =
    case result of
        Ok _ ->
            ( model, cmdNavigate <| Routing.Questionnaires Index )

        Err error ->
            ( { model | savingQuestionnaire = Error "Questionnaire could not be saved." }, Cmd.none )



{- Helpers -}


putValuesCmd : (Msg -> Msgs.Msg) -> Session -> Model -> Cmd Msgs.Msg
putValuesCmd wrapMsg session model =
    model.values
        |> encodeValues
        |> putValues model.uuid session
        |> Jwt.send PutValuesCompleted
        |> Cmd.map wrapMsg


encodeValues : Dict String String -> Encode.Value
encodeValues values =
    values
        |> Dict.toList
        |> List.map (\( k, v ) -> ( k, Encode.string v ))
        |> Encode.object


updateValues : Model -> Model
updateValues model =
    let
        values =
            model.activeChapterForm
                |> Maybe.map (getFormValues model.values)
                |> Maybe.withDefault model.values
    in
    { model | values = values }


setActiveChapter : Chapter -> Model -> Model
setActiveChapter chapter model =
    { model | activeChapter = Just chapter }


setActiveChapterForm : Model -> Model
setActiveChapterForm model =
    case model.activeChapter of
        Just chapter ->
            { model | activeChapterForm = Just <| createChapterForm chapter model.values }

        _ ->
            model



{- Form creation -}


createChapterForm : Chapter -> Dict String String -> Form
createChapterForm chapter values =
    createForm { items = List.map createQuestionFormItem chapter.questions } { values = values }


createQuestionFormItem : Question -> FormItem
createQuestionFormItem question =
    let
        descriptor =
            createFormItemDescriptor question
    in
    case question.type_ of
        "options" ->
            ChoiceFormItem descriptor (List.map createAnswerOption (question.answers |> Maybe.withDefault []))

        "list" ->
            GroupFormItem descriptor (createGroupItems question)

        "number" ->
            NumberFormItem descriptor

        "text" ->
            TextFormItem descriptor

        _ ->
            StringFormItem descriptor


createFormItemDescriptor : Question -> FormItemDescriptor
createFormItemDescriptor question =
    { name = question.uuid
    , label = question.title
    , text = Just question.text
    }


createAnswerOption : Answer -> Option
createAnswerOption answer =
    let
        descriptor =
            createOptionFormDescriptor answer
    in
    case answer.followUps of
        FollowUps [] ->
            SimpleOption descriptor

        FollowUps followUps ->
            DetailedOption descriptor (List.map createQuestionFormItem followUps)


createOptionFormDescriptor : Answer -> OptionDescriptor
createOptionFormDescriptor answer =
    { name = answer.uuid
    , label = answer.label
    , text = answer.advice
    }


createGroupItems : Question -> List FormItem
createGroupItems question =
    case question.answerItemTemplate of
        Just answerItemTemplate ->
            let
                itemName =
                    StringFormItem { name = "itemName", label = answerItemTemplate.title, text = Nothing }

                questions =
                    List.map createQuestionFormItem <| getQuestions answerItemTemplate.questions
            in
            itemName :: questions

        _ ->
            []


getQuestions : AnswerItemTemplateQuestions -> List Question
getQuestions (AnswerItemTemplateQuestions questions) =
    questions
