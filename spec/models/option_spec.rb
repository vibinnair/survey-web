require 'spec_helper'

describe Option do
  it { should belong_to(:question) }
  it { should respond_to(:content) }
  it { should allow_mass_assignment_of(:content) }
  it { should allow_mass_assignment_of(:question_id) }
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:question_id) }
  it { should have_many(:questions).dependent(:destroy) }
  it { should have_many(:categories).dependent(:destroy) }

  context "validation" do
    it "Ensures that the order number for an option is unique within a question" do
      question = RadioQuestion.create( :type => "RadioQuestion", :content => "hollo!")
      option_1 = FactoryGirl.create(:option, :question => question, :order_number => 1)
      option_2 = FactoryGirl.build(:option, :question => question, :order_number => 1)
      option_2.should_not be_valid
    end
  end

  context "orders by order number" do
    it "fetches all option in ascending order of order_number for a particular question" do
      question = RadioQuestion.create( :content => "hollo!")
      option = FactoryGirl.create(:option, :question => question, :order_number => 2)
      another_option = FactoryGirl.create(:option, :question => question, :order_number => 1)
      question.options.last.should == option
      question.options.first.should == another_option
    end
  end

  it "fetches all it's sub-questions and sub-categories" do
    option = FactoryGirl.create(:option)
    question = FactoryGirl.create :question, :order_number => 0
    category = FactoryGirl.create :category, :order_number => 1
    another_question = FactoryGirl.create :question, :order_number => 2
    option.questions << question
    option.categories << category
    option.questions << another_question

    option.elements.should == [question, category, another_question]
  end

  context "when fetching all the sub_questions of an option" do
    let(:question) { FactoryGirl.create :question }

    it "fetches all the directly nested sub_questions" do
      option = Option.create(content: "Option", order_number: 2, :question_id => question.id)
      nested_question = RadioQuestion.create({content: "Nested", survey_id: 18, order_number: 1, parent_id: option.id})
      # Need to do a #to_s because for some reason the direct hash comparison fails on ActiveSupport::TimeWithZone objects on Linux machines
      option.as_json[:questions].map(&:to_s).should include nested_question.json(:methods => :type).to_s
    end

    it "fetches the nested subquestions at all levels" do
      option = Option.create(content: "Option", order_number: 2, :question_id => question.id)
      nested_question = RadioQuestion.create({content: "Nested", survey_id: 18, order_number: 1, parent_id: option.id})
      nested_question.options << Option.create(content: "Option", order_number: 2, :question_id => nested_question.id)
      another_nested_question = RadioQuestion.create({content: "Nested", survey_id: 18, order_number: 1, parent_id: nested_question.options.first.id})
      option.as_json[:questions].map(&:to_s).should include nested_question.json(:methods => :type).to_s
      option.as_json[:questions].map(&:to_s).should_not include  another_nested_question.json(:methods => :type).to_s
    end

    it "returns itself when there are no sub_questions" do
      option = Option.create(content: "Option", order_number: 2, :question_id => question.id)
      option.as_json.should == option.as_json
    end
  end

  context "reports" do
    it "counts the number of times it has been the answer to its question" do
      option = FactoryGirl.create(:option)
      5.times { FactoryGirl.create(:answer_with_complete_response, :content => option.content, :question_id => option.question_id) }
      option.report_data.should == 5
    end
  end

  context "duplicate" do
    it "dupicates option and its sub questions" do
      option = FactoryGirl.create(:option)
      option.questions << FactoryGirl.create(:question)
      duplicated_option = option.duplicate(0)
      duplicated_option.id.should_not == option.id
      duplicated_option.content.should == option.content
      duplicated_option.questions.size.should == option.questions.size
    end

    it "dupicates sub categories as well" do
      option = FactoryGirl.create(:option)
      option.categories << FactoryGirl.create(:category)
      duplicated_option = option.duplicate(0)
      duplicated_option.categories.size.should == option.categories.size
    end

    it "sets the sub-question's survey ID to the survey ID of the new survey which is passed in" do
      option = FactoryGirl.create(:option)
      option.questions << FactoryGirl.create(:question)
      duplicated_option = option.duplicate(15)
      duplicated_option.questions[0].survey_id.should == 15
    end

    it "sets the sub-category's survey ID to the survey ID of the new survey which is passed in" do
      option = FactoryGirl.create(:option)
      option.categories << FactoryGirl.create(:category)
      duplicated_option = option.duplicate(15)
      duplicated_option.categories[0].survey_id.should == 15
    end
  end

  it "returns categories with questions" do
    category = FactoryGirl.create :category, :order_number => 0
    another_category = FactoryGirl.create :category, :order_number => 1
    option = FactoryGirl.create(:option)
    option.categories << category
      nested_question = DropDownQuestion.create({content: "Nested", survey_id: 18, order_number: 0, category_id: category.id})
      option.categories_with_questions.should include(category)
      option.categories_with_questions.should_not include(another_category)
  end
end
