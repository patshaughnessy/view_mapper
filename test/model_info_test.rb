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
end
