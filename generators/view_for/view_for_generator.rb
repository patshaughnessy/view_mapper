require File.dirname(__FILE__) + '/../../lib/view_mapper'

class ViewForGenerator < ScaffoldGenerator

  include ViewMapper

  attr_reader   :model
  attr_accessor :valid

  def initialize(runtime_args, runtime_options = {})
    super
    @source_root = self.class.lookup('scaffold').path + "/templates"
    @model = ModelInfo.new(@name)
    validate
  end

  def record
    EditableManifest.new(self) { |m| yield m }
  end

  def manifest
    super.edit do |action|
      action unless is_model_action(action) || !valid
    end
  end

  def is_model_action(action)
    is_create_model_dir_action(action) || is_model_dependency_action(action)
  end

  def is_create_model_dir_action(action)
    action[0] == :directory && action[1].include?('app/models/')
  end

  def is_model_dependency_action(action)
    action[0] == :dependency && action[1].include?('model')
  end

  def attributes
    @attributes ||= model.attributes
  end

  def validate
    logger.error(model.error) if !model.valid?
    @valid = model.valid?
  end

  def banner
    "script/generate view_for model [ --view view:view_parameter ]"
  end

end
