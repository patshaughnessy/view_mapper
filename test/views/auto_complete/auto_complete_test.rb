require File.dirname(__FILE__) + '/../../test_helper'

class AutoCompleteViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :plural_name
  attr_reader :attributes
  attr_reader :auto_complete_attributes
  attr_reader :controller_class_name
  attr_reader :table_name
  attr_reader :class_name
  attr_reader :file_name
  attr_reader :controller_singular_name

  context "A rails app that has the auto_complete plugin installed" do
    setup do
      ActionController::Base.send(:include, MockAutoComplete)
    end

    context "A view_for generator instantiated for a test model" do
      setup do
        ClassFactory :test_model
      end

      should "detect all of the text fields when no auto_complete field is specified" do
        gen = new_generator_for_test_model('view_for', ['--view', 'auto_complete'])
        assert_contains         gen.auto_complete_attributes, 'first_name'
        assert_contains         gen.auto_complete_attributes, 'last_name'
        assert_contains         gen.auto_complete_attributes, 'address'
        assert_does_not_contain gen.auto_complete_attributes, 'some_flag'
      end
    end

    context "A scaffold_for_view generator instantiated for a test model" do

      should "return an error message without an auto_complete param" do
        Rails::Generator::Base.logger.expects('error').with('No auto_complete attribute specified.')
        new_generator_for_test_model('scaffold_for_view', ['--view', 'auto_complete'])
      end
    end

    generators = %w{ view_for scaffold_for_view }
    generators.each do |gen|

      context "A #{gen} generator instantiated for a test model" do
        setup do
          ClassFactory :test_model
        end

        should "return an error message with a bad auto_complete param" do
          Rails::Generator::Base.logger.expects('error').with('Field \'blah\' does not exist.')
          new_generator_for_test_model(gen, ['--view', 'auto_complete:blah'])
        end

        should "return an error message when the auto_complete param matches a field that is not a text field" do
          Rails::Generator::Base.logger.expects('error').with('Field \'some_flag\' is not a text field.')
          new_generator_for_test_model(gen, ['--view', 'auto_complete:some_flag'])
        end
      end

      context "A #{gen} generator instantiated for a test model with auto_complete on the first and last name fields" do
        setup do
          ClassFactory :test_model
          @gen = new_generator_for_test_model(gen, ['--view', 'auto_complete:first_name,last_name'])
        end

        should "return the proper source root" do
          assert_equal File.expand_path(File.dirname(__FILE__) + '/../../..//lib/view_mapper/views/auto_complete/templates'), ViewMapper::AutoCompleteView.source_root
        end

        view_for_templates = %w{ new edit index show }
        view_for_templates.each do | template |
          should "render the #{template} template as expected" do
            @attributes = @gen.attributes
            @singular_name = @gen.singular_name
            @plural_name = @gen.plural_name
            @auto_complete_attributes = @gen.auto_complete_attributes
            template_file = File.open(@gen.source_path("view_#{template}.html.erb"))
            result = ERB.new(template_file.read, nil, '-').result(binding)
            expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/#{template}.html.erb"), 'rb')
            assert_equal expected_file.read, result
          end
        end

        should "render the layout template as expected" do
          @controller_class_name = @gen.controller_class_name
          template_file = File.open(@gen.source_path("layout.html.erb"))
          result = ERB.new(template_file.read, nil, '-').result(binding)
          expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/test_models.html.erb"))
          assert_equal expected_file.read, result
        end

        should "render the controller template as expected" do
          @controller_class_name = @gen.controller_class_name
          @table_name = @gen.table_name
          @class_name = @gen.class_name
          @file_name = @gen.file_name
          @controller_singular_name = @gen.controller_singular_name
          @auto_complete_attributes = @gen.auto_complete_attributes
          template_file = File.open(@gen.source_path("controller.rb"))
          result = ERB.new(template_file.read, nil, '-').result(binding)
          expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/test_models_controller.rb"))
          assert_equal expected_file.read, result
        end
      end

      context "A Rails generator script" do
        setup do
          ClassFactory :test_model
          @generator_script = Rails::Generator::Scripts::Generate.new
        end

        should "add the proper auto_complete route to routes.rb when run on the #{gen} generator with a valid auto_complete field" do
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
          ScaffoldForViewGenerator.any_instance.stubs(:destination_path).returns test_routes_file
          FileUtils.copy(standard_routes_file, test_routes_file)
          Rails::Generator::Commands::Create.any_instance.stubs(:route_file).returns(test_routes_file)
          @generator_script.run(generator_script_cmd_line(gen, ['--view', 'auto_complete:address']))
          assert_equal File.open(expected_routes_file).read, File.open(test_routes_file).read
          File.delete(test_routes_file)
        end
      end
    end

    context "A Rails generator script" do
      setup do
        @generator_script = Rails::Generator::Scripts::Generate.new
      end

      should "not perform any actions when run on the scaffold_for_view generator with no auto_complete field" do
        Rails::Generator::Commands::Create.any_instance.expects(:directory).never
        Rails::Generator::Commands::Create.any_instance.expects(:template).never
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:route).never
        Rails::Generator::Base.logger.stubs(:error)
        Rails::Generator::Base.logger.stubs(:route)
        @generator_script.run(generator_script_cmd_line('scaffold_for_view', ['--view', 'auto_complete']))
      end
    end
  end

end
