require File.dirname(__FILE__) + '/../../test_helper'

class ScaffoldForViewGeneratorTest < Test::Unit::TestCase

  context "A Rails generator script" do
    setup do
      @generator_script = Rails::Generator::Scripts::Generate.new
    end

    should "display usage message with no parameters when run on scaffold_for_view" do
      ScaffoldForViewGenerator.any_instance.expects(:usage).raises(Rails::Generator::UsageError, "")
      begin
        @generator_script.run(['scaffold_for_view'])
      rescue SystemExit
      end
    end

    context "run on a TestModel" do
      should "create a manifest = scaffold for TestModel" do

        directories = [
          'app/models/',
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

        Rails::Generator::Commands::Create.any_instance.stubs(:dependency)

        @generator_script.run(['scaffold_for_view', 'test_model'])
      end
    end
  end

  context "A scaffold_for_view generator" do
    setup do
      @scaffold_for_view_gen = Rails::Generator::Base.instance('scaffold_for_view', ['test_model'] )
    end

    should "not call any actions when invalid" do
      @scaffold_for_view_gen.expects(:class_collisions).never
      @scaffold_for_view_gen.expects(:directory).never
      @scaffold_for_view_gen.stubs(:template).never
      @scaffold_for_view_gen.stubs(:route_resources).never
      @scaffold_for_view_gen.stubs(:file).never
      @scaffold_for_view_gen.valid = false
      @scaffold_for_view_gen.manifest.replay(@scaffold_for_view_gen)
    end

    should "return the source root folder for the Rails scaffold generator" do
      assert_equal @scaffold_for_view_gen.class.lookup('scaffold').path + '/templates', @scaffold_for_view_gen.source_root
    end

  end

end
