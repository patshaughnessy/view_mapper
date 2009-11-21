require File.dirname(__FILE__) + '/../../test_helper'

class PaperclipViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :attributes
  attr_reader :plural_name
  attr_reader :attachments
  attr_reader :class_name
  attr_reader :migration_name
  attr_reader :table_name
  attr_reader :options

  context "A view_for generator instantiated for a test model" do
    setup do
      setup_test_model(true)
    end

    should "detect the existing attachments when no attachment is specified" do
      gen = new_generator_for_test_model('view_for', ['--view', 'paperclip'])
      assert_contains gen.attachments, 'avatar'
      assert_contains gen.attachments, 'avatar2'
    end

    should "use the specified attachments if provided" do
      gen = new_generator_for_test_model('view_for', ['--view', 'paperclip:avatar'])
      assert_equal [ 'avatar' ], gen.attachments
    end

    should "return an error message with a bad paperclip param" do
      Rails::Generator::Base.logger.expects('error').with('Attachment \'blah\' does not exist.')
      new_generator_for_test_model('view_for', ['--view', 'paperclip:blah'])
    end
  end

  context "A view_for generator instantiated for a test model missing Paperclip columns" do
    setup do
      setup_test_model(false)
    end

    should "return an error message with a bad paperclip param" do
      Rails::Generator::Base.logger.expects('error').with('Column \'avatar_file_name\' does not exist. First run script/generate paperclip testy avatar.')
      new_generator_for_test_model('view_for', ['--view', 'paperclip:avatar'])
    end
  end

  context "A test model with no attachments" do
    setup do
      setup_test_model(true)
      Testy.class_eval do
        def self.attachment_definitions
          {}
        end
      end
    end

    teardown do
      Testy.class_eval do
        def self.attachment_definitions
          { :avatar => {:validations => []}, :avatar2 => {:validations => []} }
        end
      end
    end

    should "return a warning when run with view_for when no attachment exists and not run any actions" do
      Rails::Generator::Base.logger.expects('warning').with('No paperclip attachments exist on the specified class.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).never
      Rails::Generator::Commands::Create.any_instance.expects(:template).never
      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:route).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never
      Rails::Generator::Base.logger.stubs(:error)
      Rails::Generator::Base.logger.stubs(:route)
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'paperclip']))
    end

    should "return a warning when run with scaffold_for_view when no attachment exists and not run any actions" do
      Rails::Generator::Base.logger.expects('warning').with('No paperclip attachments specified.')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).never
      Rails::Generator::Commands::Create.any_instance.expects(:template).never
      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:route).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never
      Rails::Generator::Base.logger.stubs(:error)
      Rails::Generator::Base.logger.stubs(:route)
      @generator_script = Rails::Generator::Scripts::Generate.new
      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'paperclip']))
    end
  end

  context "A scaffold_for_view generator with no model" do
    setup do
      ActiveRecord::Base.send(:include, MockPaperclip)
    end

    should "use the specified attachments if provided" do
      gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'paperclip:avatar3,avatar4'])
      assert_contains gen.attachments, 'avatar3'
      assert_contains gen.attachments, 'avatar4'
    end

    should "not detect the existing attachments when no attachment is specified" do
      Rails::Generator::Base.logger.expects('warning').with('No paperclip attachments specified.')
      gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'paperclip'])
      assert_equal [], gen.attachments
    end
  end

  context "A view_for gen with no model" do
    should "not return an error message when paperclip is installed" do
      Rails::Generator::Base.logger.expects('error').never
      ActiveRecord::Base.send(:include, MockPaperclip)
      new_generator_for_test_model('view_for', ['--view', 'paperclip:avatar'])
    end

    should "return an error message when paperclip is not installed" do
      Rails::Generator::Base.logger.expects('error').with('The Paperclip plugin does not appear to be installed.')
      ActiveRecord::Base.stubs(:methods).returns([])
      new_generator_for_test_model('view_for', ['--view', 'paperclip:avatar'])
    end
  end

  context "A view_for generator instantiated for a test model with two attachments" do
    setup do
      setup_test_model(true)
      @gen = new_generator_for_test_model('view_for', ['--view', 'paperclip'])
    end

    should "return the proper source root folder" do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/../../../lib/view_mapper/views/paperclip/templates'), @gen.source_root
    end

    view_for_templates = %w{ new edit index show }
    view_for_templates.each do | template |
      should "render the #{template} template as expected" do
        @attributes = @gen.attributes
        @singular_name = @gen.singular_name
        @plural_name = @gen.plural_name
        @attachments = @gen.attachments
        template_file = File.open(File.join(File.dirname(__FILE__), "../../../lib/view_mapper/views/paperclip/templates/view_#{template}.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/#{template}.html.erb"))
        assert_equal expected_file.read, result
      end
    end
  end

  context "A Rails generator script run on a testy model" do
    setup do
      setup_test_model(true)
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "not perform any actions when run on the view_for generator with an invalid paperclip field" do
      Rails::Generator::Commands::Create.any_instance.expects(:directory).never
      Rails::Generator::Commands::Create.any_instance.expects(:template).never
      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:route).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never
      Rails::Generator::Base.logger.stubs(:error)
      Rails::Generator::Base.logger.stubs(:route)
      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'paperclip:blah']))
    end

    should "create a normal view_for manifest when the view_for generator is run with a valid attachment" do

      directories = [
        'app/controllers/',
        'app/helpers/',
        'app/views/testies',
        'app/views/layouts/',
        'test/functional/',
        'test/unit/',
        'test/unit/helpers/',
        'public/stylesheets/'
      ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

      templates = {
        'view_index.html.erb' => 'app/views/testies/index.html.erb',
        'view_show.html.erb'  => 'app/views/testies/show.html.erb',
        'view_new.html.erb'   => 'app/views/testies/new.html.erb',
        'view_edit.html.erb'  => 'app/views/testies/edit.html.erb',
        'layout.html.erb'     => 'app/views/layouts/testies.html.erb',
        'style.css'           => 'public/stylesheets/scaffold.css',
        'controller.rb'       => 'app/controllers/testies_controller.rb',
        'functional_test.rb'  => 'test/functional/testies_controller_test.rb',
        'helper.rb'           => 'app/helpers/testies_helper.rb',
        'helper_test.rb'      => 'test/unit/helpers/testies_helper_test.rb'
      }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('testies')
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

      @generator_script.run(generator_script_cmd_line('view_for', ['--view', 'paperclip:avatar']))
    end

    should "create a manifest containing model actions when the scaffold_for_view generator is run with a valid attachment" do

      directories = [
        'app/models/',
        'app/controllers/',
        'app/helpers/',
        'app/views/testies',
        'app/views/layouts/',
        'test/functional/',
        'test/unit/',
        'test/unit/helpers/',
        'test/fixtures/',
        'public/stylesheets/'
      ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

     templates = {
        'view_index.html.erb' => 'app/views/testies/index.html.erb',
        'view_show.html.erb'  => 'app/views/testies/show.html.erb',
        'view_new.html.erb'   => 'app/views/testies/new.html.erb',
        'view_edit.html.erb'  => 'app/views/testies/edit.html.erb',
        'layout.html.erb'     => 'app/views/layouts/testies.html.erb',
        'style.css'           => 'public/stylesheets/scaffold.css',
        'controller.rb'       => 'app/controllers/testies_controller.rb',
        'functional_test.rb'  => 'test/functional/testies_controller_test.rb',
        'helper.rb'           => 'app/helpers/testies_helper.rb',
        'helper_test.rb'      => 'test/unit/helpers/testies_helper_test.rb',
        'model.rb'            => 'app/models/testy.rb',
        'unit_test.rb'        => 'test/unit/testy_test.rb',
        'fixtures.yml'        => 'test/fixtures/testies.yml'
      }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('testies')
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      Rails::Generator::Commands::Create.any_instance.expects(:dependency).never

      Rails::Generator::Commands::Create.any_instance.expects(:migration_template).with(
        'migration.rb',
        'db/migrate',
        :assigns => { :migration_name => "CreateTesties" },
        :migration_file_name => "create_testies"
      )

      @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'paperclip:avatar']))
    end
  end

  context "A scaffold_for_view generator instantiated for a test model with an avatar attachment" do
    setup do
      @gen = new_generator_for_test_model('scaffold_for_view', ['--view', 'paperclip:avatar,avatar2'])
    end

    should "render the model template as expected" do
      @class_name = @gen.class_name
      @attributes = @gen.attributes
      @attachments = @gen.attachments
      template_file = File.open(File.join(File.dirname(__FILE__), "../../../lib/view_mapper/views/paperclip/templates/model.rb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/testy.rb"))
      assert_equal expected_file.read, result
    end

    should "render the migration template as expected" do
      @class_name = @gen.class_name
      @attributes = @gen.attributes
      @attachments = @gen.attachments
      @migration_name = 'CreateTesties'
      @table_name = @gen.table_name
      @options = {}
      template_file = File.open(File.join(File.dirname(__FILE__), "../../../lib/view_mapper/views/paperclip/templates/migration.rb"))
      result = ERB.new(template_file.read, nil, '-').result(binding)
      expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/create_testies.rb"))
      assert_equal expected_file.read, result
    end
  end
end
