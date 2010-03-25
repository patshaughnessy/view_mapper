require File.dirname(__FILE__) + '/../../test_helper'

class BelongsToViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :attributes
  attr_reader :plural_name
  attr_reader :parent_models
  attr_reader :class_name
  attr_reader :migration_name
  attr_reader :table_name
  attr_reader :options

  context "A view_for generator instantiated for a test model" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model
      ClassFactory :child_model
    end

    should "detect the existing parents when no parent is specified" do
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to'], 'child_model')
      parent_models = gen.parent_models
      assert_equal 2, parent_models.size
      assert_equal 'ParentModel',       parent_models[0].name
      assert_equal 'SecondParentModel', parent_models[1].name
    end

    should "use the specified parent if provided" do
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to:parent_model'], 'child_model')
      parent_models = gen.parent_models
      assert_equal 1, parent_models.size
      assert_equal 'ParentModel', parent_models[0].name
    end

    should "return an error message with a bad parent param" do
      ClassFactory :test_model
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
      new_generator_for_test_model('view_for', ['--view', 'belongs_to:blah'])
    end
  end

  context "A scaffold_for_view generator instantiated for a test model" do

    should "return a warning when run with scaffold_for_view when no belongs_to is specified and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to']))
    end
  end

  context "A test model with no belongs_to associations" do
    setup do
      ClassFactory :test_model
    end

    should "return a error when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to associations exist in class TestModel.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to']))
    end

    should "return a error when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to']))
    end
  end

  context "A test model with a belongs_to association for a model for which it does not have a name virtual attribute" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model

      child_model_code_missing_virtual_attribute = <<END
        belongs_to :parent_model

        belongs_to :second_parent_model
        def second_parent_model_name
          'something else'
        end
        def second_parent_model_name=
        end
END
      ClassFactory :child_model, :class_eval => child_model_code_missing_virtual_attribute
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not have a method parent_model_name.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:parent_model'], 'child_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not have a method parent_model_name.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to'], 'child_model'))
    end
  end

  context "A test model with a belongs_to association for a model which does not have a name method or column" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model do |p|
        p.string :not_the_name_column
      end
      ClassFactory :child_model
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SecondParentModel does not have a name attribute.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:second_parent_model'], 'child_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SecondParentModel does not have a name attribute.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to'], 'child_model'))
    end
  end

  context "A test model with a belongs_to association for a model which has a name method but not a name column" do
    setup do
      ClassFactory :parent_model
      parent_code_with_name_method = <<SRC
        has_many :child_models
        def name
          'the name'
        end
SRC
      ClassFactory :second_parent_model, :class_eval => parent_code_with_name_method do |p|
        p.string :not_the_name_column
      end
      ClassFactory :child_model
    end

    should "continue to generate as usual" do
      stub_actions
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:second_parent_model'], 'child_model'))
    end
  end

  context "A test model with a belongs_to association for a model for which it does not have a foreign key" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model
      ClassFactory :child_model do |child|
        child.string  :name
        child.integer :parent_model_id
      end
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a foreign key for SecondParentModel.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:second_parent_model'], 'child_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model ChildModel does not contain a foreign key for SecondParentModel.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to'], 'child_model'))
    end
  end

  context "A parent model, a child model and a second parent model" do
    setup do
      ClassFactory :parent_model
      ClassFactory :second_parent_model
      ClassFactory :child_model, :class_eval => <<END
        belongs_to :parent_model
        def parent_model_name
          'something'
        end
        def parent_model_name=
        end

        belongs_to :second_parent_model
        def second_parent_model_other_field
          'something else'
        end
        def second_parent_model_other_field=
        end
END
    end
  
    context "A view_for generator instantiated for a test model with two belongs_to associations" do
      setup do
        @gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to:parent_model,second_parent_model[other_field]'], 'child_model')
      end

      should "return the proper source root" do
        assert_equal File.expand_path(File.dirname(__FILE__) + '/../../..//lib/view_mapper/views/belongs_to/templates'), ViewMapper::BelongsToView.source_root
      end

      view_for_templates = %w{ new edit index show }
      view_for_templates.each do | template |
        should "render the #{template} template as expected" do
          @attributes = @gen.attributes
          @singular_name = @gen.singular_name
          @plural_name = @gen.plural_name
          @parent_models = @gen.parent_models
          template_file = File.open(@gen.source_path("view_#{template}.html.erb"))
          result = ERB.new(template_file.read, nil, '-').result(binding)
          expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/#{template}.html.erb"))
          assert_equal expected_file.read, result
        end
      end

      should "render the form template as expected" do
        @attributes = @gen.attributes
        @singular_name = @gen.singular_name
        @plural_name = @gen.plural_name
        @parent_models = @gen.parent_models
        template_file = File.open(@gen.source_path("view_form.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/_form.html.erb"))
        assert_equal expected_file.read, result
      end
    end

    context "A scaffold_for_view generator instantiated for a test model with two belongs_to associations" do
      setup do
        @gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'belongs_to:parent_model,second_parent_model[other_field]'], 'child_model')
      end

      should "render the model template as expected" do
        @parent_models = @gen.parent_models
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        template_file = File.open(@gen.source_path("model.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/child_model.rb"))
        assert_equal expected_file.read, result
      end

      should "render the migration template as expected" do
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        @migration_name = 'CreateChildModels'
        @table_name = @gen.table_name
        @parent_models = @gen.parent_models
        @options = {}
        template_file = File.open(@gen.source_path("migration.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/create_child_models.rb"))
        assert_equal expected_file.read, result
      end
    end

    context "A Rails generator script" do
      setup do
        @generator_script = Rails::Generator::Scripts::Generate.new
      end

      should "return a warning when run with view_for on an invalid parent model and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
        @generator_script = Rails::Generator::Scripts::Generate.new
        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:blah'], 'child_model'))
      end

      should "create the correct manifest when the view_for generator is run with a valid parent model" do

        expect_no_warnings

        directories = [
          'app/controllers/',
          'app/helpers/',
          'app/views/child_models',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/child_models/index.html.erb',
          'view_new.html.erb'    => 'app/views/child_models/new.html.erb',
          'view_edit.html.erb'   => 'app/views/child_models/edit.html.erb',
          'view_show.html.erb'   => 'app/views/child_models/show.html.erb',
          'view_form.html.erb'   => 'app/views/child_models/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/child_models.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/child_models_controller.rb',
          'functional_test.rb'   => 'test/functional/child_models_controller_test.rb',
          'helper.rb'            => 'app/helpers/child_models_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/child_models_helper_test.rb'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('child_models')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:parent_model'], 'child_model'))
      end

      should "create the correct manifest when the scaffold_for_view generator is run with a valid parent model" do

        expect_no_warnings

        directories = [
          'app/models/',
          'app/controllers/',
          'app/helpers/',
          'app/views/child_models',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'test/fixtures/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/child_models/index.html.erb',
          'view_new.html.erb'    => 'app/views/child_models/new.html.erb',
          'view_edit.html.erb'   => 'app/views/child_models/edit.html.erb',
          'view_show.html.erb'   => 'app/views/child_models/show.html.erb',
          'view_form.html.erb'   => 'app/views/child_models/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/child_models.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/child_models_controller.rb',
          'functional_test.rb'   => 'test/functional/child_models_controller_test.rb',
          'helper.rb'            => 'app/helpers/child_models_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/child_models_helper_test.rb',
          'model.erb'            => 'app/models/child_model.rb',
          'unit_test.rb'         => 'test/unit/child_model_test.rb',
          'fixtures.yml'         => 'test/fixtures/child_models.yml'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('child_models')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        Rails::Generator::Commands::Create.any_instance.expects(:migration_template).with(
          'migration.rb',
          'db/migrate',
          :assigns => { :migration_name => "CreateChildModels" },
          :migration_file_name => "create_child_models"
        )

        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to:parent_model'], 'child_model'))
      end
    end

    context "A Rails generator script with a parent model without a has_many association" do
      setup do
        @generator_script = Rails::Generator::Scripts::Generate.new
        ClassFactory :parent_model, :class_eval => ''
        ClassFactory :child_model
      end

      should "return a warning when run with view_for and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('warning').with('Model ParentModel does not contain a has_many association for ChildModel.')
        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to:parent_model'], 'child_model'))
      end

      should "return a warning when run with scaffold_for_view and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('warning').with('Model ParentModel does not contain a has_many association for ChildModel.')
        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to:parent_model'], 'child_model'))
      end
    end
  end

  def field_for(parent_model)
    @gen.field_for(parent_model)
  end
end
