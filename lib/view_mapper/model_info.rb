module ViewMapper
  class ModelInfo

    attr_reader   :model
    attr_accessor :through_model # has_many :through => XYZ
    attr_reader   :name
    attr_reader   :error

    def initialize(model_name)
      @model = find_model(model_name)
      @name = model.to_s unless model.nil?
    end

    def valid?
      error.nil?
    end

    def columns
      @columns ||= active_record_columns.collect { |col| col.name }
    end

    def has_column?(col_name)
      model.column_names.include? col_name
    end

    def has_method?(method_name)
      model.new.methods.include?(method_name) || model.new.methods.include?(method_name.to_sym)
    end

    def attributes
      @attributes ||= active_record_columns.collect { |col| Rails::Generator::GeneratedAttribute.new col.name, col.type }
    end

    def self.is_text_field_attrib_type?(type)
      [:integer, :float, :decimal, :string].include? type
    end

    def text_fields
      attributes.reject { |attrib| !ModelInfo.is_text_field_attrib_type? attrib.type }.collect { |attrib| attrib.name }
    end

    def attachments
      @attachments = find_attachments
    end

    def has_attachment?(attachment)
      attachments.include?(attachment)
    end

    def has_columns_for_attachment?(attachment)
      !paperclip_columns_for_attachment(attachment).detect { |paperclip_col| !has_column_for_attachment(attachment, paperclip_col) }
    end

    def child_models
      @child_models ||= model_info_array_for_association(:has_many)
    end

    def parent_models
      @parent_models ||= model_info_array_for_association(:belongs_to)
    end

    def has_many_through_models
      @has_many_through_models ||= model_info_array_for_association(:has_many, ActiveRecord::Reflection::ThroughReflection)
    end

    def find_through_model(source_model_name)
      reflections_for_association(:has_many, ActiveRecord::Reflection::ThroughReflection).each do |kvpair|
        reflection_model_name = kvpair[0].to_s.singularize
        if reflection_model_name == source_model_name.underscore
          reflection = kvpair[1]
          return ModelInfo.new(reflection.options[:through].to_s.singularize)
        end
      end
      nil
    end

    def reflections_for_association(association_type, type)
      model.reflections.select { |key, value| value.macro == association_type && value.is_a?(type) }
    end

    def model_info_from_reflection(reflection_model_name, reflection)
      model_info = ModelInfo.new(reflection_model_name)
      if reflection.is_a? ActiveRecord::Reflection::ThroughReflection
        model_info.through_model = ModelInfo.new reflection.options[:through].to_s.singularize
      end
      model_info
    end

    def model_info_array_for_association(association_type, type = ActiveRecord::Reflection::AssociationReflection)
      reflections_for_association(association_type, type).collect do |kvpair|
        reflection_model_name = kvpair[0].to_s.singularize
        reflection = kvpair[1]
        model_info_from_reflection(reflection_model_name, reflection)
      end.sort do |a, b|
        a.name <=> b.name
      end
    end

    def accepts_nested_attributes_for?(child_model)
      if !has_method?("#{child_model.name.underscore.pluralize}_attributes=")
        @error = "Model #{model} does not accept nested attributes for model #{child_model.name}."
        false
      else
        true
      end
    end

    def belongs_to?(parent_model_name)
      !association_for(:belongs_to, parent_model_name).nil?
    end

    def has_many?(child_model_name)
      !association_for(:has_many, child_model_name).nil?
    end

    def has_and_belongs_to_many?(model_name)
      !association_for(:has_and_belongs_to_many, model_name).nil?
    end

    def has_many_through?(model_name)
      reflection = association_for(:has_many, model_name.pluralize)
      reflection && reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
    end

    def has_foreign_key_for?(parent_model_name)
      !foreign_key_for(parent_model_name).nil?
    end

    def foreign_key_for(parent_model_name)
      model.columns.detect { |col| is_foreign_key_for?(col, parent_model_name) }
    end

    private

    def find_model(model_name)
      model = nil
      begin
        model = Object.const_get model_name.camelize
        if !model.new.kind_of? ActiveRecord::Base
          @error = "Class '#{model_name}' is not an ActiveRecord::Base."
          model = nil
        end
      rescue NameError
        @error = "Class '#{model_name}' does not exist or contains a syntax error and could not be loaded."
      rescue ActiveRecord::StatementInvalid
        @error = "Table for model '#{model_name}' does not exist - run rake db:migrate first."
      end
      model
    end

    def active_record_columns
      @active_record_columns ||= inspect_active_record_columns
    end

    def inspect_active_record_columns
      model.columns.reject do |col|
        is_timestamp?(col) || is_primary_key?(col) || is_foreign_key?(col) || is_paperclip_column?(col)
      end
    end

    def is_timestamp?(col)
      %w{ updated_at updated_on created_at created_on }.include? col.name
    end

    def is_primary_key?(col)
      col.name == model.primary_key
    end

    def is_foreign_key?(col)
      model.reflections.values.detect do |reflection|
        col.name == reflection.primary_key_name
      end
    end

    def is_foreign_key_for?(col, parent_model_name)
      model.reflections.values.detect do |reflection|
        col.name == reflection.primary_key_name && reflection.name == parent_model_name.underscore.to_sym
      end
    end

    def association_for(association, model_name)
      model.reflections.values.detect do |reflection|
        reflection.name == model_name.underscore.to_sym && reflection.macro == association
      end
    end

    def is_paperclip_column?(col)
      paperclip_columns.include?(col.name)
    end

    def find_attachments
      if model.respond_to?('attachment_definitions') && model.attachment_definitions
        model.attachment_definitions.keys.collect(&:to_s).sort
      else
        []
      end
    end

    def has_column_for_attachment(attachment, paperclip_col)
      has_column = model.columns.map {|col| col.name}.include?(paperclip_col)
      if !has_column
        @error = "Column \'#{paperclip_col}\' does not exist. First run script/generate paperclip #{name.underscore} #{attachment}."
      end
      has_column
    end

    def paperclip_columns
      @paperclip_columns ||= attachments.inject([]) do |result, element|
        result + paperclip_columns_for_attachment(element)
      end
    end

    def paperclip_columns_for_attachment(attachment)
      %w{ file_name content_type file_size updated_at }.collect do |col|
        "#{attachment}_#{col}"
      end
    end
  end
end
