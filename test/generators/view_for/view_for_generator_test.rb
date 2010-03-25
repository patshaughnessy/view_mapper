require File.dirname(__FILE__) + '/../../test_helper'

class ViewForGeneratorTest < Test::Unit::TestCase

  attr_reader :singular_name
  attr_reader :plural_name
  attr_reader :attributes

  context "A Rails generator script" do
    setup do
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "display usage message with no parameters when run on view_for" do
      ViewForGenerator.any_instance.expects(:usage).raises(Rails::Generator::UsageError, "")
      begin
        @generator_script.run(['view_for'])
      rescue SystemExit
      end
    end

    should "display error message with a bad model name when run on view_for" do
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist or contains a syntax error and could not be loaded.')
      @generator_script.run(['view_for', 'blah'])
    end

    should "not call any actions when invalid" do
      Rails::Generator::Base.logger.stubs('error')
      Rails::Generator::Commands::Create.any_instance.expects(:directory).never
      Rails::Generator::Commands::Create.any_instance.expects(:template).never
      Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
      Rails::Generator::Commands::Create.any_instance.expects(:file).never
      @generator_script.run(['view_for', 'blah'])
    end

    context "run on a TestModel" do
      setup do
        ClassFactory :test_model
      end

      should "create a manifest = (scaffold for TestModel) - (model template)" do

        directories = [
          'app/controllers/',
          'app/helpers/',
          'app/views/test_models',
          'app/views/layouts/',
          'test/functional/',
          'test/unit/',
          'test/unit/helpers/',
          'public/stylesheets/'
        ].each { |path| Rails::Generator::Commands::Create.any_instance.expects(:directory).with(path) }

        templates = {
          'view_index.html.erb' => 'app/views/test_models/index.html.erb',
          'view_show.html.erb'  => 'app/views/test_models/show.html.erb',
          'view_new.html.erb'   => 'app/views/test_models/new.html.erb',
          'view_edit.html.erb'  => 'app/views/test_models/edit.html.erb',
          'layout.html.erb'     => 'app/views/layouts/test_models.html.erb',
          'style.css'           => 'public/stylesheets/scaffold.css',
          'controller.rb'       => 'app/controllers/test_models_controller.rb',
          'functional_test.rb'  => 'test/functional/test_models_controller_test.rb',
          'helper.rb'           => 'app/helpers/test_models_helper.rb',
          'helper_test.rb'      => 'test/unit/helpers/test_models_helper_test.rb'
        }.each { |template, target| Rails::Generator::Commands::Create.any_instance.expects(:template).with(template, target) }

        Rails::Generator::Commands::Create.any_instance.expects(:route_resources).with('test_models')
        Rails::Generator::Commands::Create.any_instance.expects(:file).never

        @generator_script.run(['view_for', 'test_model'])
      end
    end
  end

  context "A view_for generator" do
    setup do
      @view_for_gen = Rails::Generator::Base.instance('view_for', ['test_model'] )
      @model = ClassFactory :test_model
    end

    should "have the proper model name" do
      assert_equal @model.name, @view_for_gen.model.name
    end

    should "have the proper attributes for ERB" do
      %w{ first_name last_name address }.each_with_index do |col, i|
        assert_equal col, @view_for_gen.attributes[i].name
        assert_equal :string, @view_for_gen.attributes[i].type
      end
    end

  end
end
