module ViewMapper
  module BelongsToAutoCompleteView

    include BelongsToParentModels

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

    def auto_complete_for_method(parent_model)
      "auto_complete_for_#{parent_model.name.underscore}_#{field_for(parent_model)}"
    end

    def validate
      @valid = validate_auto_complete_installed
      @valid &&= super
      @valid &&= validate_parent_models
    end

    def validate_parent_model(parent_model, child_model_name, child_model, check_setter_method = true)
      valid = super
      if valid && !parent_model.has_column?(field_for(parent_model))
        logger.warning "Model #{parent_model.name} does not have a #{field_for(parent_model)} column."
        return false
      end
      valid
    end

    def validate_auto_complete_installed
      if !auto_complete_installed
        logger.error "The auto_complete plugin does not appear to be installed."
        return false
      end
      true
    end

    def auto_complete_installed
      ActionController::Base.methods.include?('auto_complete_for') ||
      ActionController::Base.methods.include?(:auto_complete_for)
    end

  end
end
