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
        parent_models.reverse.each do |parent_model|
          m.route :name       => 'connect',
                  :path       => auto_complete_for_method(parent_model),
                  :controller => controller_file_name,
                  :action     => auto_complete_for_method(parent_model)
        end
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

    def auto_complete_for_method(parent_model)
      "auto_complete_for_#{parent_model.name.underscore}_#{field_for(parent_model)}"
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
        model.parent_models   #.each do |parent_model|
          #select_parent_by parent_model, 'name'
          #parent_fields[parent_model.name.underscore] = 'name'
        #end
      else
        []
      end
    end

    def model_info_from_param(param)
      if /(.*)\[(.*)\]/.match(param)
        #parent_fields[model_name] = $2
        parent_model = ModelInfo.new($1.singularize)
        select_parent_by parent_model, $2
      else
        #parent_fields[param] = 'name'
        parent_model = ModelInfo.new(param.singularize)
        #select_parent_by parent_model, 'name'
      end
      parent_model
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
      #p parent_model
      #p @parent_fields
      parent_model_name = parent_model.name
      if !parent_model.valid?
        logger.error parent_model.error
        return false
      elsif view_only? && !model.belongs_to?(parent_model_name)
        logger.warning "Model #{model.name} does not belong to model #{parent_model_name}."
        return false
      elsif view_only? && !model.has_method?(virtual_attribute_for(parent_model))
        #puts caller
        logger.warning "Model #{model.name} does not have a method #{virtual_attribute_for(parent_model)}."
        return false
      elsif view_only? && !model.has_foreign_key_for?(parent_model_name)
        logger.warning "Model #{class_name} does not contain a foreign key for #{parent_model_name}."
        return false
      elsif !parent_model.has_many?(class_name.pluralize)
        logger.warning "Model #{parent_model_name} does not contain a has_many association for #{class_name}."
        return false
      elsif !parent_model.has_column?(field_for(parent_model))
        logger.warning "Model #{parent_model_name} does not have a #{field_for(parent_model)} column."
        return false
      end
      true
    end

#    def attribute_for_parent(parent_model)
#      name = parent_model.name.underscore
#      parent_fields[name]
#    end
#
#    def virtual_attribute_method_for_parent(parent_model)
#      name = parent_model.name.underscore
#      "#{name}_#{parent_fields[name]}"
#    end

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

    def field_for(parent_model)
      name = parent_fields[parent_model.name]
      name ? name : 'name'
    end

    def virtual_attribute_for(parent_model)
      "#{parent_model.name.underscore}_#{field_for(parent_model)}"
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
