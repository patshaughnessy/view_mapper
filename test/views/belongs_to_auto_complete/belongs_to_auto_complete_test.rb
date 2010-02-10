require File.dirname(__FILE__) + '/../../test_helper'

class BelongsToAutoCompleteViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :attributes
  attr_reader :plural_name
  attr_reader :parent_models
  attr_reader :class_name
  attr_reader :migration_name
  attr_reader :table_name
  attr_reader :options
  attr_reader :controller_class_name
  attr_reader :file_name

  context "A view_for generator instantiated for a test model" do
    setup do
      setup_test_model
      setup_parent_test_model
    end

    should "detect the existing parents when no parent is specified" do
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete'], 'some_other_model')
      parent_models = gen.parent_models
      assert_equal 1, parent_models.size
      assert_equal 'Parent', parent_models[0].name
    end

    should "use the specified parent if provided" do
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete:parent'], 'some_other_model')
      parent_models = gen.parent_models
      assert_equal 1, parent_models.size
      assert_equal 'Parent', parent_models[0].name
    end

    should "return an error message with a bad parent param" do
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
      new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete:blah'])
    end

    should "use 'name' as the default parent field" do
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete:parent'], 'some_other_model')
      assert_equal 'name', gen.field_for(ViewMapper::ModelInfo.new('parent'))
    end

    should "parse the parent model field" do
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method parent_first_name.')
      gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete:parent[first_name]'], 'some_other_model')
      assert_equal 'first_name', gen.field_for(ViewMapper::ModelInfo.new('parent'))
    end
  end

  context "A scaffold_for_view generator instantiated for a test model" do
    setup do
      setup_test_model
      setup_parent_test_model
    end

    should "return a warning when run with scaffold_for_view when no belongs_to_auto_complete is specified and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to_auto_complete']))
    end
  end

  context "A test model with no belongs_to associations" do
    setup do
      setup_test_model
      setup_parent_test_model(true, false)
    end

    should "return a error when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to associations exist in class Testy.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete']))
    end

    should "return a error when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No belongs_to association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to_auto_complete']))
    end
  end

  context "A test model with a belongs_to association for a model for which it does not have a name virtual attribute" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model(true, false)
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method second_parent_name.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:second_parent'], 'some_other_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method second_parent_name.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete'], 'some_other_model'))
    end
  end

  context "A test model with a belongs_to association for a model for which it does not have a name virtual attribute setter" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model(false, true)
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method second_parent_name=.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:second_parent'], 'some_other_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method second_parent_name=.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete'], 'some_other_model'))
    end
  end

  context "A test model with a belongs_to association for a model that has some other virtual attribute missing" do
    setup do
      setup_test_model
      setup_parent_test_model
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not have a method parent_first_name.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent[first_name]'], 'some_other_model'))
    end
  end

  context "A test model with a belongs_to association for a model which does not have a name method or column" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model(true, true, true, false, false)
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SecondParent does not have a name attribute.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:second_parent'], 'some_other_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SecondParent does not have a name attribute.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete'], 'some_other_model'))
    end
  end

  context "A test model with a belongs_to association for a model which does not have some other attribute or column" do
    setup do
      setup_test_model
      setup_parent_test_model
      ViewMapper::ModelInfo.any_instance.stubs(:has_method?).returns(:true)
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Parent does not have a missing_field column.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent[missing_field]'], 'some_other_model'))
    end
  end

  context "A test model with a belongs_to association for a model for which it does not have a foreign key" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model(true, true, false)
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not contain a foreign key for SecondParent.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:second_parent'], 'some_other_model'))
    end

    should "return a warning and not include the problem model when run with view_for but continue to run for other models" do
      stub_actions
      Rails::Generator::Base.logger.expects('warning').with('Model SomeOtherModel does not contain a foreign key for SecondParent.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete'], 'some_other_model'))
    end
  end

  context "A view_for generator instantiated for a test model with two belongs_to associations" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model
      @gen = new_generator_for_test_model('view_for', ['--view', 'belongs_to_auto_complete:parent,second_parent[other_field]'], 'some_other_model')
    end

    should "return the proper source root" do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/../../..//lib/view_mapper/views/belongs_to_auto_complete/templates'), ViewMapper::BelongsToAutoCompleteView.source_root
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

    should "render the layout template as expected" do
      @controller_class_name = @gen.controller_class_name
      template_file = File.open(@gen.source_path("layout.html.erb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/some_other_models.html.erb"))
      assert_equal expected_file.read, result
    end

    should "render the controller template as expected" do
      @controller_class_name = @gen.controller_class_name
      @table_name = @gen.table_name
      @class_name = @gen.class_name
      @file_name = @gen.file_name
      @controller_class_name = @gen.controller_class_name
      @parent_models = @gen.parent_models
      template_file = File.open(@gen.source_path("controller.rb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/some_other_models_controller.rb"))
      assert_equal expected_file.read, result
    end
  end

  context "A scaffold_for_view generator instantiated for a test model with two belongs_to associations" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model
      @gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'belongs_to_auto_complete:parent,second_parent[other_field]'], 'some_other_model')
    end

    should "render the model template as expected" do
      @parent_models = @gen.parent_models
      @class_name = @gen.class_name
      @attributes = @gen.attributes
      template_file = File.open(@gen.source_path("model.rb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/some_other_model.rb"))
      assert_equal expected_file.read, result
    end

    should "render the migration template as expected" do
      @class_name = @gen.class_name
      @attributes = @gen.attributes
      @migration_name = 'CreateSomeOtherModels'
      @table_name = @gen.table_name
      @parent_models = @gen.parent_models
      @options = {}
      template_file = File.open(@gen.source_path("migration.rb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/create_some_other_models.rb"))
      assert_equal expected_file.read, result
    end
  end

  context "A Rails generator script" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "add the proper auto_complete route to routes.rb" do
      Rails::Generator::Commands::Create.any_instance.stubs(:directory)
      Rails::Generator::Commands::Create.any_instance.stubs(:template)
      Rails::Generator::Commands::Create.any_instance.stubs(:route_resources)
      Rails::Generator::Commands::Create.any_instance.stubs(:file)
      Rails::Generator::Commands::Create.any_instance.stubs(:dependency)
      Rails::Generator::Base.logger.stubs(:route)

      expected_path = File.dirname(__FILE__) + '/expected_templates'
      standard_routes_file = expected_path + '/standard_routes.rb'
      expected_routes_file = expected_path + '/expected_routes.rb'
      test_routes_file = expected_path + '/routes.rb'
      ViewForGenerator.any_instance.stubs(:destination_path).returns test_routes_file
      File.copy(standard_routes_file, test_routes_file)
      Rails::Generator::Commands::Create.any_instance.stubs(:route_file).returns(test_routes_file)
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent,second_parent[other_field]'], 'some_other_model'))
      assert_equal File.open(expected_routes_file).read, File.open(test_routes_file).read
      File.delete(test_routes_file)
    end
  end

  context "A Rails generator script" do
    setup do
      setup_test_model
      setup_parent_test_model
      setup_second_parent_test_model
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for on an invalid parent model and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:blah'], 'some_other_model'))
    end

    should "create the correct manifest when the view_for generator is run with a valid parent model" do

      expect_no_warnings

      directories = [
        'app/controllers/',
        'app/helpers/',
        'app/views/some_other_models',
        'app/views/layouts/',
        'test/functional/',
        'test/unit/',
        'test/unit/helpers/',
        'public/stylesheets/'
      ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

      templates = {
        'view_index.html.erb'  => 'app/views/some_other_models/index.html.erb',
        'view_new.html.erb'    => 'app/views/some_other_models/new.html.erb',
        'view_edit.html.erb'   => 'app/views/some_other_models/edit.html.erb',
        'view_show.html.erb'   => 'app/views/some_other_models/show.html.erb',
        'view_form.html.erb'   => 'app/views/some_other_models/_form.html.erb',
        'layout.html.erb'      => 'app/views/layouts/some_other_models.html.erb',
        'style.css'            => 'public/stylesheets/scaffold.css',
        'controller.rb'        => 'app/controllers/some_other_models_controller.rb',
        'functional_test.rb'   => 'test/functional/some_other_models_controller_test.rb',
        'helper.rb'            => 'app/helpers/some_other_models_helper.rb',
        'helper_test.rb'       => 'test/unit/helpers/some_other_models_helper_test.rb'
      }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('some_other_models')
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

      Rails::Generator::Commands::Create.any_instance.expects(:route).with(
        :path => 'auto_complete_for_parent_name',
        :name => 'connect',
        :action => 'auto_complete_for_parent_name',
        :controller => 'some_other_models')

      Rails::Generator::Commands::Create.any_instance.expects(:route).with(
        :path => 'auto_complete_for_second_parent_other_field',
        :name => 'connect',
        :action => 'auto_complete_for_second_parent_other_field',
        :controller => 'some_other_models')

      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent,second_parent[other_field]'], 'some_other_model'))
    end

    should "create the correct manifest when the scaffold_for_view generator is run with a valid parent model" do

      expect_no_warnings

      directories = [
        'app/models/',
        'app/controllers/',
        'app/helpers/',
        'app/views/some_other_models',
        'app/views/layouts/',
        'test/functional/',
        'test/unit/',
        'test/unit/helpers/',
        'test/fixtures/',
        'public/stylesheets/'
      ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

      templates = {
        'view_index.html.erb'  => 'app/views/some_other_models/index.html.erb',
        'view_new.html.erb'    => 'app/views/some_other_models/new.html.erb',
        'view_edit.html.erb'   => 'app/views/some_other_models/edit.html.erb',
        'view_show.html.erb'   => 'app/views/some_other_models/show.html.erb',
        'view_form.html.erb'   => 'app/views/some_other_models/_form.html.erb',
        'layout.html.erb'      => 'app/views/layouts/some_other_models.html.erb',
        'style.css'            => 'public/stylesheets/scaffold.css',
        'controller.rb'        => 'app/controllers/some_other_models_controller.rb',
        'functional_test.rb'   => 'test/functional/some_other_models_controller_test.rb',
        'helper.rb'            => 'app/helpers/some_other_models_helper.rb',
        'helper_test.rb'       => 'test/unit/helpers/some_other_models_helper_test.rb',
        'model.rb'            => 'app/models/some_other_model.rb',
        'unit_test.rb'        => 'test/unit/some_other_model_test.rb',
        'fixtures.yml'        => 'test/fixtures/some_other_models.yml'
      }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('some_other_models')
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

      Rails::Generator::Commands::Create.any_instance.expects(:migration_template).with(
        'migration.rb',
        'db/migrate',
        :assigns => { :migration_name => "CreateSomeOtherModels" },
        :migration_file_name => "create_some_other_models"
      )

      Rails::Generator::Commands::Create.any_instance.expects(:route).with(
        :path => 'auto_complete_for_parent_name',
        :name => 'connect',
        :action => 'auto_complete_for_parent_name',
        :controller => 'some_other_models')

      Rails::Generator::Commands::Create.any_instance.expects(:route).with(
        :path => 'auto_complete_for_second_parent_other_field',
        :name => 'connect',
        :action => 'auto_complete_for_second_parent_other_field',
        :controller => 'some_other_models')

      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to_auto_complete:parent,second_parent[other_field]'], 'some_other_model'))
    end
  end

  context "A Rails generator script with a parent model without a has_many association" do
    setup do
      setup_test_model
      setup_parent_test_model(true, true, false)
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Parent does not contain a has_many association for SomeOtherModel.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent'], 'some_other_model'))
    end

    should "return a warning when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Parent does not contain a has_many association for SomeOtherModel.')
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'belongs_to_auto_complete:parent'], 'some_other_model'))
    end
  end

  context "A Rails generator script" do
    setup do
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return an error when run when the auto_complete plugin is not installed" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('The auto_complete plugin does not appear to be installed.')
      ActionController::Base.stubs(:methods).returns([])
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'belongs_to_auto_complete:parent'], 'some_other_model'))
    end
  end

  def field_for(parent_model)
    @gen.field_for(parent_model)
  end
end
