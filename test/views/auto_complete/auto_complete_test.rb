require 'test_helper'

class AutoCompleteViewTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :plural_name
  attr_reader :attributes
  attr_reader :auto_complete_attribute
  attr_reader :controller_class_name
  attr_reader :table_name
  attr_reader :class_name
  attr_reader :file_name
  attr_reader :controller_singular_name

  generators = %w{ view_for scaffold_for_view }
  generators.each do |gen|

    context "A #{gen} generator instantiated for a test model" do
      should "return an error message without an auto_complete param" do
        Rails::Generator::Base.logger.expects('error').with('No auto_complete attribute specified.')
        new_generator_for_test_model(gen, ['--view', 'auto_complete'])
      end

      should "return an error message with a bad auto_complete param" do
        Rails::Generator::Base.logger.expects('error').with('Field \'blah\' does not exist.')
        new_generator_for_test_model(gen, ['--view', 'auto_complete:blah'])
      end
    end

    context "A #{gen} generator instantiated for a test model with auto_complete on the first_name field" do
      setup do
        @gen = new_generator_for_test_model(gen, ['--view', 'auto_complete:first_name'])
      end

      should "find the auto complete column name" do
        assert_equal 'first_name', @gen.auto_complete_attribute
      end

      should "have the correct auto_complete_for method name" do
        assert_equal 'auto_complete_for_testy_first_name', @gen.auto_complete_for_method
      end
    end

    context "A #{gen} generator instantiated for a test model with auto_complete on the address field" do
      setup do
        @gen = new_generator_for_test_model(gen, ['--view', 'auto_complete:address'])
      end

      should "return the proper source root folder" do
        assert_equal './test/../lib/view_mapper/auto_complete_templates', @gen.source_root
      end

      view_for_templates = %w{ new edit index show }
      view_for_templates.each do | template |
        should "render the #{template} template as expected" do
          @attributes = @gen.attributes
          @singular_name = @gen.singular_name
          @plural_name = @gen.plural_name
          @auto_complete_attribute = @gen.auto_complete_attribute
          template_file = File.open(File.join(File.dirname(__FILE__), "/../lib/view_mapper/auto_complete_templates/view_#{template}.html.erb"))
          result = ERB.new(template_file.read, nil, '-').result(binding)
          expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/auto_complete/#{template}.html.erb"))
          assert_equal expected_file.read, result
        end
      end

      should "render the layout template as expected" do
        @controller_class_name = @gen.controller_class_name
        template_file = File.open(File.join(File.dirname(__FILE__), "/../lib/view_mapper/auto_complete_templates/layout.html.erb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/auto_complete/testies.html.erb"))
        assert_equal expected_file.read, result
      end

      should "render the controller template as expected" do
        @controller_class_name = @gen.controller_class_name
        @table_name = @gen.table_name
        @class_name = @gen.class_name
        @file_name = @gen.file_name
        @controller_singular_name = @gen.controller_singular_name
        @auto_complete_attribute = @gen.auto_complete_attribute
        template_file = File.open(File.join(File.dirname(__FILE__), "/../lib/view_mapper/auto_complete_templates/controller.rb"))
        result = ERB.new(template_file.read, nil, '-').result(binding)
        expected_file = File.open(File.join(File.dirname(__FILE__), "expected_templates/auto_complete/testies_controller.rb"))
        assert_equal expected_file.read, result
      end
    end

    context "A Rails generator script" do
      setup do
        setup_test_model
        @generator_script = Rails::Generator::Scripts::Generate.new
      end

      should "add the proper auto_complete route to routes.rb when run on the #{gen} generator with a valid auto_complete field" do
        Rails::Generator::Commands::Create.any_instance.stubs(:directory)
        Rails::Generator::Commands::Create.any_instance.stubs(:template)
        Rails::Generator::Commands::Create.any_instance.stubs(:route_resources)
        Rails::Generator::Commands::Create.any_instance.stubs(:file)
        Rails::Generator::Commands::Create.any_instance.stubs(:dependency)
        Rails::Generator::Base.logger.stubs(:route)

        expected_path = File.dirname(__FILE__) + '/expected_templates/auto_complete'
        standard_routes_file = expected_path + '/standard_routes.rb'
        expected_routes_file = expected_path + '/expected_routes.rb'
        test_routes_file = expected_path + '/routes.rb'
        ViewForGenerator.any_instance.stubs(:destination_path).returns test_routes_file
        ScaffoldForViewGenerator.any_instance.stubs(:destination_path).returns test_routes_file
        File.copy(standard_routes_file, test_routes_file)
        Rails::Generator::Commands::Create.any_instance.stubs(:route_file).returns(test_routes_file)
        @generator_script.run(generator_script_cmd_line(gen, ['--view', 'auto_complete:address']))
        assert_equal File.open(expected_routes_file).read, File.open(test_routes_file).read
        File.delete(test_routes_file)
      end

      should "not perform any actions when run on the #{gen} generator with no auto_complete field" do
        Rails::Generator::Commands::Create.any_instance.expects(:directory).never
        Rails::Generator::Commands::Create.any_instance.expects(:template).never
        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
        Rails::Generator::Commands::Create.any_instance.expects(:file).never
        Rails::Generator::Commands::Create.any_instance.expects(:route).never
        Rails::Generator::Base.logger.stubs(:error)
        Rails::Generator::Base.logger.stubs(:route)
        @generator_script.run(generator_script_cmd_line(gen, ['--view', 'auto_complete']))
      end
    end
  end

end
