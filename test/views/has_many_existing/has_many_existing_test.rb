require File.dirname(__FILE__) + '/../../test_helper'

class HasManyExistingViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :attributes
  attr_reader :plural_name
  attr_reader :has_many_through_models
  attr_reader :hmt_model
  attr_reader :class_name
  attr_reader :migration_name
  attr_reader :table_name
  attr_reader :options

  context "When a target model and a through model exist" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      ClassFactory :assignment
    end

    should "detect the existing hmt models when no parent is specified" do
      gen = new_generator_for_test_model('view_for', ['--view', 'has_many_existing'], 'programmer')
      has_many_through_models = gen.has_many_through_models
      assert_equal 1, has_many_through_models.size
      assert_equal 'Project', has_many_through_models[0].name
      assert_equal 'Assignment', has_many_through_models[0].through_model.name
    end

    should "use find the specified valid child model if provided" do
      gen = new_generator_for_test_model('view_for', ['--view', 'has_many_existing:projects'], 'programmer')
      has_many_through_models = gen.has_many_through_models
      assert_equal 1, has_many_through_models.size
      assert_equal 'Project', has_many_through_models[0].name
      assert_equal 'Assignment', has_many_through_models[0].through_model.name
    end

    should "return an error message with a bad child model param" do
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
      gen = new_generator_for_test_model('view_for', ['--view', 'has_many_existing:blah'], 'programmer')
      assert_equal [], gen.has_many_through_models
    end
  end

  context "A test model with no hmt associations" do
    setup do
      ClassFactory :test_model
    end

    should "return a error when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No has_many through associations exist in class TestModel.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing']))
    end

    should "return a error when run with scaffold_for_view and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('error').with('No has_many through association specified.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many_existing']))
    end
  end

  context "A through model with a belongs_to association for an hmt model for which it does not have a name virtual attribute" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
through_model_code = <<SRC
belongs_to :project
belongs_to :programmer
SRC
      ClassFactory :assignment, :class_eval => through_model_code
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Assignment does not have a method project_name.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A through model with a belongs_to association for an hmt model which does not have a name method or column" do
    setup do
      ClassFactory :project do |p|
        p.string :not_the_name_column
      end
      ClassFactory :assignment
      ClassFactory :programmer
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Project does not have a name attribute.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A through model with a belongs_to association for an hmt model which has a name method but not a name column" do
    setup do
      parent_code_with_name_method = <<SRC
        has_many :programmers, :through => :assignments
        has_many :assignments
        def name
          'the name'
        end
SRC
      ClassFactory :project, :class_eval => parent_code_with_name_method do |p|
        p.string :not_the_name_column
      end
      ClassFactory :assignment
      ClassFactory :programmer
    end

    should "continue to generate as usual" do
      stub_actions
      Rails::Generator::Commands::Create.any_instance.expects(:directory).with('app/controllers/')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A through model with a belongs_to association for an hmt model for which it does not have a foreign key" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      ClassFactory :assignment do |a|
        a.integer :not_the_project_id
        a.integer :programmer_id
      end
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Assignment does not contain a foreign key for Project.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A through model with a belongs_to association for an hmt model for which it does not have a foreign key for the source model" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      ClassFactory :assignment do |a|
        a.integer :project_id
        a.integer :not_the_programmer_id
      end
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Assignment does not contain a foreign key for Programmer.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A Rails generator script with an hmt model without a has_many association for the through model" do
    setup do
      @generator_script = Rails::Generator::Scripts::Generate.new
      has_many_through_code = <<SRC
has_many :programmers, :through => :assignments
SRC
      ClassFactory :project, :class_eval => has_many_through_code
      ClassFactory :programmer
      ClassFactory :assignment
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Project does not contain a has_many association for Assignment.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A Rails generator script with an hmt model without a has_many association for the source model" do
    setup do
      @generator_script = Rails::Generator::Scripts::Generate.new
      has_many_through_code = <<SRC
has_many :assignments
SRC
      ClassFactory :project, :class_eval => has_many_through_code
      ClassFactory :programmer
      ClassFactory :assignment
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Project does not contain a has_many through association for Programmer.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A Rails generator script with a child model without a belongs_to association for the source model" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      through_model_code = <<SRC
belongs_to :project
def project_name
  'something'
end
def project_name=
end
SRC
      ClassFactory :assignment, :class_eval => through_model_code
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Assignment does not contain a belongs_to association for Programmer.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A Rails generator script with a child model without a belongs_to association for the hmt model" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      through_model_code = <<SRC
belongs_to :programmer
def project_name
  'something'
end
def project_name=
end
SRC
      ClassFactory :assignment, :class_eval => through_model_code
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "return a warning when run with view_for and not run any actions" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Assignment does not belong to model Project.')
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "A test model with a has_many through association with a through model for which it does not accept nested attributes" do
    setup do
      missing_nested_attribute_code = <<SRC
has_many :projects, :through => :assignments
has_many :assignments
SRC
      ClassFactory :project
      ClassFactory :programmer, :class_eval => missing_nested_attribute_code
      ClassFactory :assignment
    end

    should "return a warning and stop when the problem model is specified" do
      expect_no_actions
      Rails::Generator::Base.logger.expects('warning').with('Model Programmer does not accept nested attributes for model Assignment.')
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
    end
  end

  context "When a target model and a through model exist" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      ClassFactory :assignment
    end

    context "A Rails generator script" do
      setup do
        @generator_script = Rails::Generator::Scripts::Generate.new
      end

      should "return a warning when run with view_for on an invalid child model and not run any actions" do
        expect_no_actions
        Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
        @generator_script = Rails::Generator::Scripts::Generate.new
        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:blah'], 'programmer'))
      end

      should "create the correct manifest when the view_for generator is run with valid htm models" do

        expect_no_warnings

        directories = [
          'app/controllers/',
          'app/helpers/',
          'app/views/programmers',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/programmers/index.html.erb',
          'view_new.html.erb'    => 'app/views/programmers/new.html.erb',
          'view_edit.html.erb'   => 'app/views/programmers/edit.html.erb',
          'view_form.html.erb'   => 'app/views/programmers/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/programmers.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/programmers_controller.rb',
          'functional_test.rb'   => 'test/functional/programmers_controller_test.rb',
          'helper.rb'            => 'app/helpers/programmers_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/programmers_helper_test.rb'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        project_model_info = ViewMapper::ModelInfo.new('project')
        assignment_model_info = ViewMapper::ModelInfo.new('assignment')
        programmer_info = ViewMapper::ModelInfo.new('Programmer')
        ViewMapper::ModelInfo.stubs(:new).with('project').returns(project_model_info)
        ViewMapper::ModelInfo.stubs(:new).with('programmer').returns(programmer_info)
        ViewMapper::ModelInfo.stubs(:new).with('Programmer').returns(programmer_info)
        ViewMapper::ModelInfo.stubs(:new).with('assignment').returns(assignment_model_info)
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_show.html.erb',
          'app/views/programmers/show.html.erb',
          { :assigns => { :has_many_through_models => [ project_model_info ] } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_child_form.html.erb',
          'app/views/programmers/_assignment.html.erb',
          { :assigns => { :hmt_model => project_model_info } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:file).with(
          'nested_attributes.js', 'public/javascripts/nested_attributes.js'
        )
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('programmers')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'has_many_existing:projects'], 'programmer'))
      end

      should "create the correct manifest when the scaffold_for_view generator is run with valid htm models" do

        expect_no_warnings

        directories = [
          'app/models/',
          'app/controllers/',
          'app/helpers/',
          'app/views/programmers',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'test/fixtures/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb'  => 'app/views/programmers/index.html.erb',
          'view_new.html.erb'    => 'app/views/programmers/new.html.erb',
          'view_edit.html.erb'   => 'app/views/programmers/edit.html.erb',
          'view_form.html.erb'   => 'app/views/programmers/_form.html.erb',
          'layout.html.erb'      => 'app/views/layouts/programmers.html.erb',
          'style.css'            => 'public/stylesheets/scaffold.css',
          'controller.rb'        => 'app/controllers/programmers_controller.rb',
          'functional_test.rb'   => 'test/functional/programmers_controller_test.rb',
          'helper.rb'            => 'app/helpers/programmers_helper.rb',
          'helper_test.rb'       => 'test/unit/helpers/programmers_helper_test.rb',
          'model.rb'             => 'app/models/programmer.rb',
          'unit_test.rb'         => 'test/unit/programmer_test.rb',
          'fixtures.yml'         => 'test/fixtures/programmers.yml'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        project_model_info = ViewMapper::ModelInfo.new('project')
        assignment_model_info = ViewMapper::ModelInfo.new('assignment')
        programmer_info = ViewMapper::ModelInfo.new('Programmer')
        ViewMapper::ModelInfo.stubs(:new).with('project').returns(project_model_info)
        ViewMapper::ModelInfo.stubs(:new).with('programmer').returns(programmer_info)
        ViewMapper::ModelInfo.stubs(:new).with('Programmer').returns(programmer_info)
        ViewMapper::ModelInfo.stubs(:new).with('assignment').returns(assignment_model_info)
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_show.html.erb',
          'app/views/programmers/show.html.erb',
          { :assigns => { :has_many_through_models => [ project_model_info ] } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:template).with(
          'view_child_form.html.erb',
          'app/views/programmers/_assignment.html.erb',
          { :assigns => { :hmt_model => project_model_info } }
        )
        Rails::Generator::Commands::Create.any_instance.expects(:file).with(
          'nested_attributes.js', 'public/javascripts/nested_attributes.js'
        )
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('programmers')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

        Rails::Generator::Commands::Create.any_instance.expects(:migration_template).with(
          'migration.rb',
          'db/migrate',
          :assigns => { :migration_name => "CreateProgrammers" },
          :migration_file_name => "create_programmers"
        )

        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'has_many_existing:projects'], 'programmer'))
      end

    end
  end

  context "When a target model and a through model exist" do
    setup do
      ClassFactory :project
      ClassFactory :programmer
      ClassFactory :assignment do |a|
        a.string  :name
        a.integer :project_id
        a.integer :programmer_id
      end
    end

    context "A view_for generator" do
      setup do
        @gen = new_generator_for_test_model('view_for', ['--view', 'has_many_existing:projects'], 'programmer')
      end

      should "return the proper source root" do
        assert_equal File.expand_path(File.dirname(__FILE__) + '/../../..//lib/view_mapper/views/has_many_existing/templates'), ViewMapper::HasManyExistingView.source_root
      end

      view_for_templates = %w{ new edit show index }
      view_for_templates.each do | template |
        should "render the #{template} template as expected" do
          @attributes = @gen.attributes
          @singular_name = @gen.singular_name
          @plural_name = @gen.plural_name
          @child_models = @gen.child_models
          @has_many_through_models = @gen.has_many_through_models
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
        @has_many_through_models = @gen.has_many_through_models
        template_file = File.open(@gen.source_path("view_form.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/_form.html.erb"))
        assert_equal expected_file.read, result
      end

      should "render the child model partial as expected" do
        @hmt_model = @gen.has_many_through_models[0]
        template_file = File.open(@gen.source_path("view_child_form.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/_assignment.html.erb"))
        assert_equal expected_file.read, result
      end
    end

    context "A scaffold_for_view generator" do
      setup do
        @gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'has_many_existing:projects'], 'programmer')
      end

      should "render the model template as expected" do
        @has_many_through_models = @gen.has_many_through_models
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        template_file = File.open(@gen.source_path("model.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/programmer.rb"))
        assert_equal expected_file.read, result
      end

      should "render the migration template as expected" do
        @class_name = @gen.class_name
        @attributes = @gen.attributes
        @migration_name = 'CreateProgrammers'
        @table_name = @gen.table_name
        @options = {}
        template_file = File.open(@gen.source_path("migration.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/create_programmers.rb"))
        assert_equal expected_file.read, result
      end
    end
  end

  def field_for(parent_model)
    @gen.field_for(parent_model)
  end
end

