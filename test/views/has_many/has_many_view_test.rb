require File.dirname(__FILE__) + '/../../test_helper'

class HasManyViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :attributes
  attr_reader :plural_name
  attr_reader :child_models
  attr_reader :child_model
  attr_reader :class_name
  attr_reader :migration_name
  attr_reader :table_name
  attr_reader :options

  context "When a parent model that has two child models exists" do
    setup do
      has_two_child_models_code = <<SRC
has_many :child_models
has_many :second_child_models
def child_models_attributes=
  'fake'
end
def second_child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => has_two_child_models_code
      ClassFactory :child_model
      ClassFactory :second_child_model
    end

    context "A view_for generator instantiated for a test model" do

      should "detect the existing child models when no child model is specified" do
        gen = new_generator_for_test_model('view_for', ['--view', 'has_many'], 'parent_model')
        child_models = gen.child_models
        assert_equal 2,                  child_models.size
        assert_equal 'ChildModel',       child_models[0].name
        assert_equal 'SecondChildModel', child_models[1].name
        assert_equal [ 'name' ],         child_models[0].columns
        assert_equal [ 'first_name', 'last_name', 'address', 'some_flag' ], child_models[1].columns
      end

      should "use find the specified valid child model if provided" do
        gen = new_generator_for_test_model('view_for', ['--view', 'has_many:child_models'], 'parent_model')
        child_models = gen.child_models
        assert_equal 'ChildModel', child_models[0].name
        assert_equal 1,            child_models.size
      end

      should "be able to parse two model names" do
        gen = new_generator_for_test_model('view_for', ['--view', 'has_many:child_models,second_child_models'], 'parent_model')
        child_models = gen.child_models
        assert_equal 2,                  child_models.size
        assert_equal 'ChildModel',       child_models[0].name
        assert_equal 'SecondChildModel', child_models[1].name
        assert_equal [ 'name' ],         child_models[0].columns
        assert_equal [ 'first_name', 'last_name', 'address', 'some_flag' ], child_models[1].columns
      end

      should "return an error message with a bad child model param" do
        Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
        gen = new_generator_for_test_model('view_for', ['--view', 'has_many:blah'], 'parent_model')
        assert_equal [], gen.child_models
      end
    end

    context "A scaffold_for_view generator instantiated for a test model" do
      should "return a warning when run with scaffold_for_view when no has_many is specified and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('error').with('No has_many association specified.')
        @generator_script = Rails::Generator::Scripts::Generate.new
        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many'], 'parent_model'))
      end
    end

    context "A view_for generator instantiated for a test model with two has_many associations" do
      setup do
        @gen = new_generator_for_test_model('view_for', ['--view', 'has_many:child_models,second_child_models'], 'parent_model')
      end

      should "return the proper source root" do
        assert_equal File.expand_path(File.dirname(__FILE__) + '/../../..//lib/view_mapper/views/has_many/templates'), ViewMapper::HasManyView.source_root
      end

      view_for_templates = %w{ new edit show index }
      view_for_templates.each do | template |
        should "render the #{template} template as expected" do
          @attributes = @gen.attributes
          @singular_name = @gen.singular_name
          @plural_name = @gen.plural_name
          @child_models = @gen.child_models
          template_file = File.open(@gen.source_path("view_#{template}.html.erb"))
          result = ERB.new(template_file.read, nil, '-').result(binding)
          expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/#{template}.html.erb"))
          assert_equal expected_file.read, result
        end
      end

      should "render the form partial as expected" do
        @attributes = @gen.attributes
        @singular_name = @gen.singular_name
        @plural_name = @gen.plural_name
        @child_models = @gen.child_models
        template_file = File.open(@gen.source_path("view_form.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/_form.html.erb"))
        assert_equal expected_file.read, result
      end

      should "render the child model partial as expected" do
        @child_model = @gen.child_models[1]
        template_file = File.open(@gen.source_path("view_child_form.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/_second_child_model.html.erb"))
        assert_equal expected_file.read, result
      end
    end

    context "A scaffold_for_view generator instantiated for a test model with two has_many associations" do
      setup do
        @gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'has_many:child_models,second_child_models'], 'parent_model')
      end

      should "render the model template as expected" do
        @child_models = @gen.child_models
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        template_file = File.open(@gen.source_path("model.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/parent_model.rb"))
        assert_equal expected_file.read, result
      end

      should "render the migration template as expected" do
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        @migration_name = 'CreateParentModels'
        @table_name = @gen.table_name
        @options = {}
        template_file = File.open(@gen.source_path("migration.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/create_parent_models.rb"))
        assert_equal expected_file.read, result
      end
    end

    context "A Rails generator script" do
      setup do
        @generator_script = Rails::Generator::Scripts::Generate.new
      end

      should "return a warning when run with view_for on an invalid child model and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
        @generator_script = Rails::Generator::Scripts::Generate.new
        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:blah'], 'parent_model'))
      end

      should "create the correct manifest when the view_for generator is run with a valid child model" do

        expect_no_warnings

        directories = [
          'app/controllers/',
          'app/helpers/',
          'app/views/parent_models',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/parent_models/index.html.erb',
          'view_new.html.erb'    => 'app/views/parent_models/new.html.erb',
          'view_edit.html.erb'   => 'app/views/parent_models/edit.html.erb',
          'view_form.html.erb'   => 'app/views/parent_models/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/parent_models.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/parent_models_controller.rb',
          'functional_test.rb'   => 'test/functional/parent_models_controller_test.rb',
          'helper.rb'            => 'app/helpers/parent_models_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/parent_models_helper_test.rb'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        child_model_model_info = ViewMapper::ModelInfo.new('child_model')
        parent_model_info = ViewMapper::ModelInfo.new('parent_model')
        ViewMapper::ModelInfo.stubs(:new).with('child_model').returns(child_model_model_info)
        ViewMapper::ModelInfo.stubs(:new).with('parent_model').returns(parent_model_info)
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_show.html.erb',
          'app/views/parent_models/show.html.erb',
          { :assigns => { :child_models => [ child_model_model_info ] } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_child_form.html.erb',
          'app/views/parent_models/_child_model.html.erb',
          { :assigns => { :child_model => child_model_model_info } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:file).with(
          'nested_attributes.js', 'public/javascripts/nested_attributes.js'
        )
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('parent_models')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
      end

      should "create the correct manifest when the scaffold_for_view generator is run with a valid child model" do

        expect_no_warnings

        directories = [
          'app/models/',
          'app/controllers/',
          'app/helpers/',
          'app/views/parent_models',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'test/fixtures/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/parent_models/index.html.erb',
          'view_new.html.erb'    => 'app/views/parent_models/new.html.erb',
          'view_edit.html.erb'   => 'app/views/parent_models/edit.html.erb',
          'view_form.html.erb'   => 'app/views/parent_models/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/parent_models.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/parent_models_controller.rb',
          'functional_test.rb'   => 'test/functional/parent_models_controller_test.rb',
          'helper.rb'            => 'app/helpers/parent_models_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/parent_models_helper_test.rb',
          'model.rb'            => 'app/models/parent_model.rb',
          'unit_test.rb'        => 'test/unit/parent_model_test.rb',
          'fixtures.yml'        => 'test/fixtures/parent_models.yml'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        child_model_model_info = ViewMapper::ModelInfo.new('child_model')
        parent_model_model_info = ViewMapper::ModelInfo.new('parent_model')
        ViewMapper::ModelInfo.stubs(:new).with('child_model').returns(child_model_model_info)
        ViewMapper::ModelInfo.stubs(:new).with('parent_model').returns(parent_model_model_info)
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_show.html.erb',
          'app/views/parent_models/show.html.erb',
          { :assigns => { :child_models => [ child_model_model_info ] } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_child_form.html.erb',
          'app/views/parent_models/_child_model.html.erb',
          { :assigns => { :child_model => child_model_model_info } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:file).with(
          'nested_attributes.js', 'public/javascripts/nested_attributes.js'
        )
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('parent_models')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        Rails::Generator::Commands::Create.any_instance.expects(:migration_template).with(
          'migration.rb',
          'db/migrate',
          :assigns => { :migration_name => "CreateParentModels" },
          :migration_file_name => "create_parent_models"
        )

        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many:child_models'], 'parent_model'))
      end
    end
  end

  context "A test model with no has many associations" do
    setup do
      ClassFactory :test_model
    end

    should "return a error when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No has_many associations exist in class TestModel.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many']))
    end

    should "return a error when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No has_many association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many']))
    end
  end

  context "A Rails generator script with a child model without a belongs_to association" do
    setup do
      has_child_model_code = <<SRC
has_many :child_models
def child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => has_child_model_code

      missing_belongs_to_code = <<END
  def parent_model_name
    'something'
  end
  def parent_model_name=
  end
END
      ClassFactory :child_model, :class_eval => missing_belongs_to_code do |child|
        child.string  :name
        child.integer :parent_model_id
      end

      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a belongs_to association for ParentModel.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
    end

    should "return a warning when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a belongs_to association for ParentModel.')
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many:child_models'], 'parent_model'))
    end
  end

  context "A Rails generator script with a child model missing a foreign key" do
    setup do
      has_child_model_code = <<SRC
has_many :child_models
def child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => has_child_model_code
      ClassFactory :child_model, :class_eval => 'belongs_to :parent_model' do |child|
        child.string  :name
      end

      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a foreign key for ParentModel.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
    end

    should "return a warning when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a foreign key for ParentModel.')
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many:child_models'], 'parent_model'))
    end
  end

  context "A Rails generator script with a child model that has a habtm association" do
    setup do
      has_two_child_models_code = <<SRC
has_many :child_models
def child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => has_two_child_models_code
      ClassFactory :child_model, :class_eval => 'has_and_belongs_to_many :parent_models'
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "not return a warning when run with view_for" do
      stub_actions
      expect_no_warnings
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
    end

    should "not return a warning when run with scaffold_for_view" do
      stub_actions
      expect_no_warnings
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many:child_models'], 'parent_model'))
    end
  end

  context "A Rails generator script with a child model that has_many (through) association" do
    setup do
      has_two_child_models_code = <<SRC
has_many :child_models
def child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => has_two_child_models_code
      ClassFactory :child_model, :class_eval => 'has_many :parent_models'
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "not return a warning when run with view_for" do
      stub_actions
      expect_no_warnings
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
    end

    should "not return a warning when run with scaffold_for_view" do
      stub_actions
      expect_no_warnings
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many:child_models'], 'parent_model'))
    end
  end

  context "A test model with a has_many association for a model for which it does not accept nested attributes" do
    setup do
      missing_nested_attribute_code = <<SRC
has_many :child_models
has_many :second_child_models
def second_child_models_attributes=
  'fake'
end
SRC
      ClassFactory :parent_model, :class_eval => missing_nested_attribute_code
      ClassFactory :child_model
      ClassFactory :second_child_model
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ParentModel does not accept nested attributes for model ChildModel.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many:child_models'], 'parent_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ParentModel does not accept nested attributes for model ChildModel.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many'], 'parent_model'))
    end
  end

end