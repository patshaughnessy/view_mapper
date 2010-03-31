require 'test_helper'

class ModelInfoTest < Test::Unit::TestCase

  context "A model info object created for a test model" do
    setup do
      ClassFactory :test_model
      @model_info = ViewMapper::ModelInfo.new('test_model')
    end

    should "find the model" do
      assert_equal TestModel, @model_info.model
    end

    should "return the model's name" do
      assert_equal 'TestModel', @model_info.name
    end

    should "return the model's columns and not the primary key or time stamp columns" do
      assert_equal [ 'first_name', 'last_name', 'address', 'some_flag' ], @model_info.columns
    end

    should "return the model's Rails Generator attributes" do
      attribs = @model_info.attributes
      assert_equal 4, attribs.size
      assert_kind_of Rails::Generator::GeneratedAttribute, attribs[0]
      assert_kind_of Rails::Generator::GeneratedAttribute, attribs[1]
      assert_kind_of Rails::Generator::GeneratedAttribute, attribs[2]
      assert_equal 'first_name', attribs[0].name
      assert_equal 'last_name',  attribs[1].name
      assert_equal 'address',    attribs[2].name
    end

    should "return the model's text fields" do
      text_fields = @model_info.text_fields
      assert_equal 3, text_fields.size
      assert_equal 'first_name', text_fields[0]
      assert_equal 'last_name',  text_fields[1]
      assert_equal 'address',    text_fields[2]
    end
  end

  context "Child and parent model info objects" do
    setup do
      ClassFactory :parent_model, :class_eval => 'has_many :second_child_models'
      ClassFactory :second_child_model
      @child_model = ViewMapper::ModelInfo.new('second_child_model')
      @parent_model = ViewMapper::ModelInfo.new('parent_model')
    end

    should "not include the parent foreign key column in the child model's columns" do
      assert_equal [ 'first_name', 'last_name', 'address', 'some_flag' ], @child_model.columns
    end

    should "determine that the child model belongs to the parent model" do
      assert_equal true, @child_model.belongs_to?('parent_model')
    end

    should "determine that the parent model has many child models" do
      assert_equal true, @parent_model.has_many?('second_child_models')
    end

    should "return the child's foreign key for the parent" do
      assert_equal 'parent_model_id', @child_model.foreign_key_for('parent_model').name
      assert_equal true,  @child_model.has_foreign_key_for?('parent_model')
      assert_equal nil,   @child_model.foreign_key_for('invalid_model')
      assert_equal false, @child_model.has_foreign_key_for?('invalid_model')
    end
  end

  context "Two model info objects for models that in a habtm association" do
    setup do
      ClassFactory :parent_model
      ClassFactory :child_model, :class_eval => 'has_and_belongs_to_many :parent_models'
      @child_model = ViewMapper::ModelInfo.new('child_model')
      @parent_model = ViewMapper::ModelInfo.new('parent_model')
    end

    should "determine that a habtm association exists" do
      assert_equal true, @child_model.has_and_belongs_to_many?('parent_models')
    end
  end

  context "A model info object created for a test model that has Paperclip attachments" do
    setup do
      ClassFactory :test_model
      @model_info = ViewMapper::ModelInfo.new('test_model')
    end

    should "not include the Paperclip columns in the model's columns" do
      assert_equal [ 'first_name', 'last_name', 'address', 'some_flag' ], @model_info.columns
    end
  end

  context "A model info object created with two models in a has_many/belongs_to setup" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model
      ClassFactory :child_model
    end

    should "return the proper child model" do
      parent_model_info = ViewMapper::ModelInfo.new('parent_model')
      child_models = parent_model_info.child_models
      assert_equal 1, child_models.size
      assert_equal 'ChildModel', child_models[0].name
      assert_equal ChildModel,   child_models[0].model
      assert_equal nil,          child_models[0].through_model
    end

    should "return the proper parent model" do
      child_model_info = ViewMapper::ModelInfo.new('child_model')
      parent_models = child_model_info.parent_models
      assert_equal 2, parent_models.size
      assert_equal 'ParentModel',       parent_models[0].name
      assert_equal ParentModel,         parent_models[0].model
      assert_equal nil,                 parent_models[0].through_model
      assert_equal 'SecondParentModel', parent_models[1].name
      assert_equal SecondParentModel,   parent_models[1].model
      assert_equal nil,                 parent_models[1].through_model
    end
  end

  context "A model info object created with three models in a has_many through setup" do
    setup do
      ClassFactory :programmer
      ClassFactory :project
      ClassFactory :assignment
      @programmer_info = ViewMapper::ModelInfo.new('programmer')
    end

    should "return the proper through reflection model" do
      hmt_models = @programmer_info.has_many_through_models
      assert_equal 1,         hmt_models.size
      assert_equal 'Project', hmt_models[0].name
      assert_equal Project,   hmt_models[0].model
      assert_equal 'Assignment', hmt_models[0].through_model.name
      assert_equal Assignment,   hmt_models[0].through_model.model
    end

    should "return the both the target and through models as child models" do
      child_models = @programmer_info.child_models
      assert_equal 2, child_models.size
      assert_equal 'Assignment', child_models[0].name
      assert_equal Assignment,   child_models[0].model
      assert_equal 'Project',    child_models[1].name
      assert_equal Project,      child_models[1].model
    end

    should "determine that a has_many_through association exists" do
      assert_equal true, @programmer_info.has_many_through?('projects')
    end

    should  "find the through model later" do
      hmt_model = ViewMapper::ModelInfo.new('project')
      through_model = hmt_model.find_through_model('Programmer')
      assert_equal 'Assignment', through_model.name
      assert_equal Assignment,   through_model.model
    end
  end
end
