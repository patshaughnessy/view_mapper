require 'test_helper'

class EditableManifestTest < Test::Unit::TestCase

  def record
    EditableManifest.new(self) { |m| yield m }
  end

  def action(param)
    @actions_received << param
  end

  context "An editable manifest with a couple of recorded actions" do
    setup do
      @actions_received = []
      @man = record do |m|
        m.action('one')
        m.action('two')
      end
    end

    should "allow me to delete an action" do
      @man.edit do |action|
        action unless action[1].include? 'one'
      end
      @man.replay(self)
      assert_does_not_contain @actions_received, 'one'
      assert_contains @actions_received, 'two'
    end

  end
end
