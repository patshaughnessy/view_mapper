module ViewMapper
  module BelongsToParentModels

    def add_model_actions(m)
      m.directory(File.join('test/fixtures', class_path))
      m.template   'model.erb',     File.join('app/models', class_path, "#{file_name}.rb")
      m.template   'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
      unless options[:skip_fixture]
        m.template 'fixtures.yml', File.join('test/fixtures', "#{table_name}.yml")
      end
      unless options[:skip_migration]
        m.migration_template 'migration.rb',
                             'db/migrate',
                             :assigns => { :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}" },
                             :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
    end

    def is_model_dependency_action(action)
      action[0] == :dependency && action[1].include?('model')
    end

    def parent_models
      @parent_models ||= find_parent_models
    end

    def find_parent_models
      if view_param
        view_param.split(',').collect do |param|
          model_info_from_param(param)
        end
      elsif view_only?
        model.parent_models
      else
        []
      end
    end

    def model_info_from_param(param)
      if /(.*)\[(.*)\]/.match(param)
        parent_model = ModelInfo.new($1.singularize)
        select_parent_by parent_model, $2
      else
        parent_model = ModelInfo.new(param.singularize)
      end
      parent_model
    end

    def validate_parent_models
      parents = parent_models
      if parents.empty?
        if view_only?
          logger.error "No belongs_to associations exist in class #{model.name}."
        else
          logger.error "No belongs_to association specified."
        end
        return false
      end
      parents.reject! { |parent_model| !validate_parent_model(parent_model, class_name, view_only? ? model : nil) }
      @parent_models = parents
      !parents.empty?
    end

    def validate_parent_model(parent_model, child_model_name, child_model, check_setter_method = false)
      parent_model_name = parent_model.name
      if !parent_model.valid?
        logger.error parent_model.error
        return false
      elsif child_model && !child_model.belongs_to?(parent_model_name)
        logger.warning "Model #{child_model.name} does not belong to model #{parent_model_name}."
        return false
      elsif child_model && !child_model.has_method?(virtual_attribute_for(parent_model))
        logger.warning "Model #{child_model.name} does not have a method #{virtual_attribute_for(parent_model)}."
        return false
      elsif child_model && check_setter_method && !child_model.has_method?(virtual_attribute_setter_for(parent_model))
        logger.warning "Model #{child_model.name} does not have a method #{virtual_attribute_setter_for(parent_model)}."
        return false
      elsif child_model && !child_model.has_foreign_key_for?(parent_model_name)
        logger.warning "Model #{child_model.name} does not contain a foreign key for #{parent_model_name}."
        return false
      elsif !parent_model.has_many?(child_model_name.pluralize)
        logger.warning "Model #{parent_model_name} does not contain a has_many association for #{child_model_name}."
        return false
      elsif !parent_model.has_method?(field_for(parent_model)) && !parent_model.has_column?(field_for(parent_model))
        logger.warning "Model #{parent_model_name} does not have a #{field_for(parent_model)} attribute."
        return false
      end
      true
    end

    def field_for(parent_model)
      name = parent_fields[parent_model.name]
      name ? name : 'name'
    end

    def virtual_attribute_for(parent_model)
      "#{parent_model.name.underscore}_#{field_for(parent_model)}"
    end

    def virtual_attribute_setter_for(parent_model)
      "#{virtual_attribute_for(parent_model)}="
    end

    private

    def select_parent_by(parent_model, field)
      parent_fields[parent_model.name] = field
    end

    def parent_fields
      @parent_fields ||= {}
    end

  end
end

