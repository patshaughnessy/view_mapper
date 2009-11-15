require 'test_helper'

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

    context "run on a Testy model" do
      should "create a manifest = scaffold for Testy" do

        directories = [
          'app/models/',
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

        Rails::Generator::Commands::Create.any_instance.stubs(:dependency)

        @generator_script.run(['scaffold_for_view', 'testy'])
      end
    end
  end

  context "A scaffold_for_view generator" do
    setup do
      @scaffold_for_view_gen = Rails::Generator::Base.instance('scaffold_for_view', ['testy'] )
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
      assert_equal './test/rails_generator/generators/components/scaffold/templates', @scaffold_for_view_gen.source_root
    end

  end

end
