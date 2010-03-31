module ViewMapper
  module HasManyChildModels

    attr_reader :child_models

    def is_child_model_action?(action)
      is_model_dependency_action(action) || is_view_show(action)
    end

    def is_model_dependency_action(action)
      action[0] == :dependency && action[1].include?('model')
    end

    def is_view_show(action)
      action[0] == :template && action[1].include?('view_show.html.erb')
    end

    def add_child_models_manifest(m)
      add_child_model_actions(m) if valid && !view_only?
      add_child_model_forms(m) if valid
      m
    end

    def add_child_model_forms(m)
      m.template(
        "view_show.html.erb",
        File.join('app/views', controller_class_path, controller_file_name, "show.html.erb"),
        { :assigns => { :child_models => child_models } }
      )
      m.template(
        "view_form.html.erb",
        File.join('app/views', controller_class_path, controller_file_name, "_form.html.erb")
      )
      child_models.each do |child_model|
        m.template(
          "view_child_form.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "_#{child_model.name.underscore}.html.erb"),
          { :assigns => { :child_model => child_model } }

        )
      end
      m.file('nested_attributes.js', 'public/javascripts/nested_attributes.js')
      m
    end

    def add_child_model_actions(m)
      m.directory(File.join('test/fixtures', class_path))
      m.template   'model.rb',     File.join('app/models', class_path, "#{file_name}.rb")
      m.template   'unit_test.rb', File.join('test/unit',  class_path, "#{file_name}_test.rb")
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

    def child_models
      @child_models ||= find_child_models
    end

    def find_child_models
      if view_param
        view_param.split(',').collect { |param| ModelInfo.new(param.singularize) }
      elsif view_only?
        model.child_models
      else
        []
      end
    end

    def validate_child_models
      cms = child_models
      if cms.empty?
        if view_only?
          logger.error "No has_many associations exist in class #{model.name}."
        else
          logger.error "No has_many association specified."
        end
        return false
      end
      cms.reject! { |child_model| !validate_child_model(child_model, class_name, view_only? ? model : nil) }
      @child_models = cms
      !cms.empty?
    end

    def validate_child_model(child_model, parent_model_name, parent_model)
      if !child_model.valid?
        logger.error child_model.error
        return false
      elsif parent_model && !parent_model.accepts_nested_attributes_for?(child_model)
        logger.warning "Model #{parent_model.name} does not accept nested attributes for model #{child_model.name}."
        return false
      else
        if child_model.has_many?(parent_model_name.pluralize) || child_model.has_and_belongs_to_many?(parent_model_name.pluralize)
          true
        elsif !child_model.belongs_to?(parent_model_name)
          logger.warning "Model #{child_model.name} does not contain a belongs_to association for #{parent_model_name}."
          return false
        elsif !child_model.has_foreign_key_for?(parent_model_name)
          logger.warning "Model #{child_model.name} does not contain a foreign key for #{parent_model_name}."
          return false
        end
      end
      true
    end

    def validate_child_model_associations(child_model)
      if child_model.belongs_to?(class_name)
        true
      else
        child_model.has_many?(class_name.pluralize) || child_model.has_and_belongs_to_many?(class_name.pluralize)
      end
    end
  end
end

