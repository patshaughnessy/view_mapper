require 'test_helper'

class ViewMapperTest < Test::Unit::TestCase

  context "A rails generator script with a view option specified" do
    setup do
      @gen = Rails::Generator::Base.instance('fake', ['testy', 'name:string', '--view', 'fake'])
    end

    should "use the specified view" do
      assert_equal 'fake', @gen.view_name
    end

    should "use the templates for the specified view" do
      assert_equal '/some/path/templates', @gen.source_root
    end
  end

  context "A rails generator script with a view option and parameter specified" do
    setup do
      @gen = Rails::Generator::Base.instance('fake', ['testy', 'name:string', '--view', 'fake:value'])
    end

    should "pass the view parameter to the specified view" do
      assert_equal 'value', @gen.view_param
      assert_equal 'fake', @gen.view_name
    end
  end
end
