module ViewMapper
  module BelongsToView

    include BelongsToParentModels

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [ BelongsToView.source_root, File.expand_path(source_root), File.join(self.class.lookup('model').path, 'templates') ]
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

    def validate
      super
      @valid &&= validate_parent_models
    end

  end
end
