require 'will_paginate/array'

class SurveysController < ApplicationController
  load_and_authorize_resource

  before_filter :require_draft_survey, :only => [:build]

  def index
    @surveys ||= []
    @surveys = @surveys.finalized  if params[:finalized].present?
    @surveys = @surveys.drafts if params[:drafts].present?
    @surveys = @surveys.paginate(:page => params[:page], :per_page => 5)
    @surveys = SurveyDecorator.decorate(@surveys)
    @organizations = Organization.all(access_token)
  end

  def destroy
    survey = Survey.find(params[:id])
    survey.destroy
    flash[:notice] = t "flash.survey_deleted"
    redirect_to(surveys_path)
  end

  def create
    @survey = Survey.new(params[:survey])
    @survey.organization_id = current_user_org

    @survey.name ||= I18n.t('js.untitled_survey')
    @survey.expiry_date ||= 5.days.from_now
    @survey.description ||= "Description goes here"

    @survey.save
    flash[:notice] = t "flash.survey_created"
    redirect_to survey_build_path(:survey_id => @survey.id)
  end

  def build
    @survey = SurveyDecorator.find(params[:survey_id])
  end

  def finalize
    survey = Survey.find(params[:survey_id])
    survey.finalize
    flash[:notice] = t "flash.survey_finalized", :survey_name => survey.name
    redirect_to edit_survey_publication_path(survey.id)
  end

  def duplicate
    survey = Survey.find(params[:id])
    if survey.duplicate(:organization_id => current_user_org).save(:validate => false)
      redirect_to :back, :notice => t('surveys.duplicate.survey_duplicated')
    else
      redirect_to :back, :error => t('surveys.duplicate.duplication_error')
    end
  end

  def report
    @survey = SurveyDecorator.find(params[:id])
    @markers = @survey.responses.to_gmaps4rails
  end

  private

  def require_draft_survey
    survey = Survey.find(params[:survey_id])
    if survey.finalized?
      flash[:error] = t "flash.edit_finalized_survey"
      redirect_to root_path
    end
  end
end
