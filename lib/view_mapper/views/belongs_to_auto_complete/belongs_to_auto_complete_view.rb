module ViewMapper
  module BelongsToAutoCompleteView

    attr_reader :parent_models

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [ BelongsToAutoCompleteView.source_root, File.expand_path(source_root), File.join(self.class.lookup('model').path, 'templates') ]
    end

    def manifest
      m = super.edit do |action|
        action unless is_model_dependency_action(action) || !valid
      end
      if valid
        m.template(
          "view_form.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "_form.html.erb")
        )
        add_model_actions(m) unless view_only?
      end
      m
    end

    def add_model_actions(m)
      m.directory(File.join('test/fixtures', class_path))
      m.template   'model.rb',     File.join('app/models', class_path, "#{file_name}.rb")
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
        view_param.split(',').collect { |param| ModelInfo.new(param.singularize) }
      elsif view_only?
        model.parent_models
      else
        []
      end
    end

    def validate
      @valid = validate_auto_complete_installed
      @valid &&= super
      @valid &&= validate_parent_models
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
      parents.reject! { |parent_model| !validate_parent_model(parent_model) }
      @parent_models = parents
      !parents.empty?
    end

    def validate_parent_model(parent_model)
      if !parent_model.valid?
        logger.error parent_model.error
        return false
      elsif view_only? && !model.belongs_to?(parent_model.name)
        logger.warning "Model #{model.name} does not belong to model #{parent_model.name}."
        return false
      elsif view_only? && !model.has_virtual_name_method?(parent_model.name)
        logger.warning "Model #{model.name} does not have a method #{parent_model.name.underscore}_name."
        return false
      elsif view_only? && !model.has_foreign_key_for?(parent_model.name)
        logger.warning "Model #{class_name} does not contain a foreign key for #{parent_model.name}."
        return false
      elsif !parent_model.has_many?(class_name.pluralize)
        logger.warning "Model #{parent_model.name} does not contain a has_many association for #{class_name}."
        return false
      elsif !parent_model.has_column?('name') && !parent_model.has_method?('name')
        logger.warning "Model #{parent_model.name} does not have a name attribute."
        return false
      end
      true
    end

    def validate_auto_complete_installed
      if !auto_complete_installed
        logger.error "The auto_complete plugin does not appear to be installed."
        return false
      end
      true
    end

    def auto_complete_installed
      ActionController::Base.methods.include? 'auto_complete_for'
    end
  end
end
