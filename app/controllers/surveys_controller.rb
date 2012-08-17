class SurveysController < ApplicationController

  def index
    @surveys = Survey.paginate(:page => params[:page], :per_page => 10)
  end
  
  def new
    @survey = Survey.new
    @survey.questions << Question.new
  end

  def create
    @survey = Survey.new(params[:survey])

    if @survey.save
      redirect_to root_path
      flash[:notice] = "Survey successfully created"
    else
      render :new
    end
  end

  def destroy
    survey = Survey.find(params[:id])
    survey.destroy
    flash[:notice] = "Survey deleted"
    redirect_to(surveys_path)
  end
end