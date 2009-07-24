class NestedAttributesViewForGenerator < ViewForGenerator

  attr_reader   :child_model
  attr_reader   :child_model_name
  attr_reader   :child_columns

  ARG_PREFIX = 'containing'

  def initialize(runtime_args, runtime_options = {})
    super
    if child_model_name.nil?
      logger.error "Required parameter 'containing' missing. Please specify the child model like this: script/generate nested_attributes_view_for group containing:people"
    end
    child_model_name
    @child_model = find_model child_model_name
    if validate_models
      inspect_child_model_columns
    else
      @child_model = nil
    end
  end

  def inspect_child_model_columns
    @child_columns = inspect_model_columns child_model
    @child_columns.reject! do |col|
      col.name == "#{model_name.underscore}_id"
    end
  end

  def child_model_name
    selected_args = @args.select do |arg|
      arg_prefix(arg) == ARG_PREFIX
    end
    @child_model_name ||= arg_value(selected_args[0]).singularize.camelize
  end

  def child_form_name
    "#{child_model_name.underscore}_form"
  end

  def child_plural_name
    child_model_name.pluralize.underscore
  end

  def child_attributes
    @child_attributes ||= attributes_from_columns(child_columns)
  end

  protected

    def banner
      "Banner for nested attributes view for generator TBD"
    end

    def valid
      super && !child_model.nil?
    end

    def validate_models
      validate_parent_has_many_children &&
      validate_child_belongs_to_parent &&
      validate_parent_accepts_nested_attributes_for_children
    end

    def validate_parent_has_many_children
      pass = model.reflections.has_key? child_plural_name.to_sym
      logger.warning "Model '#{model_name}' does not contain a has_many association for child models '#{child_plural_name}'" if !pass
      pass
    end

    def validate_parent_accepts_nested_attributes_for_children
      pass = model.new.methods.include? "#{child_plural_name}_attributes="
      logger.error "Model '#{model_name}' does not accept nested attributes for child models '#{child_plural_name}'" if !pass
      pass
    end

    def validate_child_belongs_to_parent
      pass = child_model.reflections.has_key? model_name.underscore.to_sym
      logger.warning "Model '#{child_model_name}' does not contain a belongs_to association for parent model '#{model_name}'" if !pass
      pass
    end

    def arg_prefix(string)
      string.split(':')[0]
    end

    def arg_value(string)
      string.split(':')[1]
    end

end
