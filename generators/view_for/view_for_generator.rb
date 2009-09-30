require File.dirname(__FILE__) + '/../../lib/view_mapper'

class ViewForGenerator < ScaffoldGenerator

  include ViewMapper

  attr_reader   :model
  attr_accessor :valid

  BUILT_IN_COLUMNS = [ 'id', 'created_at', 'updated_at' ]

  def initialize(runtime_args, runtime_options = {})
    super
    @source_root = source_root_for_view
    find_model @name
    @columns = custom_columns unless model.nil?
    validate
  end

  def source_root_for_view
    self.class.lookup('scaffold').path + "/templates"
  end

  def find_model(model_name)
    @model = nil
    begin
      @model = Object.const_get model_name.camelize
      if !model.new.kind_of? ActiveRecord::Base
        logger.error "Class '#{model_name}' is not an ActiveRecord::Base."
        @model = nil
      end
    rescue NameError
      logger.error "Class '#{model_name}' does not exist."
    rescue ActiveRecord::StatementInvalid
      logger.error "Table for model '#{model_name}' does not exist - run rake db:migrate first."
    end
  end

  def custom_columns
    @model.columns.reject do |col|
      BUILT_IN_COLUMNS.include? col.name
    end
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
    @attributes_from_columns ||= attributes_from_columns
  end

  def attributes_from_columns
    @columns.collect do |col|
      Rails::Generator::GeneratedAttribute.new col.name, col.type
    end
  end

  def validate
    @valid = !model.nil?
  end

  def banner
    "script/generate view_for model [ --view view:view_parameter ]"
  end

end
