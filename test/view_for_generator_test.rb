require 'test_helper'

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
      Rails::Generator::Base.logger.expects('error').with('Class \'blah\' does not exist.')
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

    context "run on a Testy model" do
      setup do
        @model = setup_test_model
      end

      should "create a manifest = (scaffold for Testy) - (model template)" do

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

        @generator_script.run(['view_for', 'testy'])
      end
    end
  end

  context "A view_for generator" do
    setup do
      @view_for_gen = Rails::Generator::Base.instance('view_for', ['testy'] )
      @model = setup_test_model
    end

    should "have the proper model name" do
      assert_equal @model, @view_for_gen.model
    end

    should "have the proper attributes for ERB" do
      %w{ first_name last_name address }.each_with_index do |col, i|
        assert_equal col, @view_for_gen.attributes[i].name
        assert_equal :string, @view_for_gen.attributes[i].type
      end
    end

  end
end
