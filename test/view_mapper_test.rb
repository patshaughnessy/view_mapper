require 'test_helper'

class ViewMapperTest < Test::Unit::TestCase

  context "A rails generator script with a view option specified" do
    setup do
      @gen = new_generator_for_test_model('fake', ['testy', 'name:string', '--view', 'fake'])
    end

    should "use the specified view" do
      assert_equal 'fake', @gen.view_name
    end

    should "have the proper default value for source_roots_for_view" do
      assert_equal [
        File.expand_path(File.dirname(__FILE__) + '/views/fake/templates'),
        File.expand_path(File.dirname(__FILE__) + '/generators/fake/templates')
      ], @gen.source_roots_for_view
    end

    should "use the correct source path for a template file that is overridden in the view" do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/views/fake/templates/fake_template1.html.erb'), @gen.source_path('fake_template1.html.erb')
    end

    should "use the correct source path for a template file that is not overridden in the view" do
      assert_equal File.expand_path(File.dirname(__FILE__) + '/generators/fake/templates/fake_template2.html.erb'), @gen.source_path('fake_template2.html.erb')
    end
  end

  context "A rails generator script with a view option and parameter specified" do
    setup do
      @gen = new_generator_for_test_model('fake', ['testy', 'name:string', '--view', 'fake:value'])
    end

    should "pass the view parameter to the specified view" do
      assert_equal 'value', @gen.view_param
      assert_equal 'fake', @gen.view_name
    end
  end
end
