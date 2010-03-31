module ViewMapper
  module HasManyExistingView

    include BelongsToParentModels
    include HasManyChildModels

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [
        HasManyExistingView.source_root,
        HasManyView.source_root,
        File.expand_path(source_root),
        File.join(self.class.lookup('model').path, 'templates')
      ]
    end

    def manifest
      m = super.edit do |action|
        action unless is_child_model_action?(action)
      end
      add_through_models_manifest(m)
      m
    end

    def add_through_models_manifest(m)
      add_child_model_actions(m) if valid && !view_only?
      add_through_model_forms(m) if valid
      m
    end

    def add_through_model_forms(m)
      m.template(
        "view_show.html.erb",
        File.join('app/views', controller_class_path, controller_file_name, "show.html.erb"),
        { :assigns => { :has_many_through_models => has_many_through_models } }
      )
      m.template(
        "view_form.html.erb",
        File.join('app/views', controller_class_path, controller_file_name, "_form.html.erb")
      )
      has_many_through_models.each do |hmt_model|
        m.template(
          "view_child_form.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "_#{hmt_model.through_model.name.underscore}.html.erb"),
          { :assigns => { :hmt_model => hmt_model } }

        )
      end
      m.file('nested_attributes.js', 'public/javascripts/nested_attributes.js')
      m
    end

    def validate
      super
      @valid &&= validate_hmt_models
    end

    def has_many_through_models
      @hmt_models ||= find_hmt_models
    end

    def find_hmt_models
      if view_param
        view_param.split(',').collect do |param|
          hmt_model_info_from_param(param)
        end
      elsif view_only?
        model.has_many_through_models
      else
        []
      end
    end

    def hmt_model_info_from_param(param)
      if /(.*)\[(.*)\]/.match(param)
        hmt_model = ModelInfo.new($1.singularize)
        select_parent_by hmt_model, $2
      else
        hmt_model = ModelInfo.new(param.singularize)
      end
      hmt_model
    end

    def validate_hmt_models
      models = has_many_through_models
      if models.empty?
        if view_only?
          logger.error "No has_many through associations exist in class #{model.name}."
        else
          logger.error "No has_many through association specified."
        end
        return false
      end
      models.reject! { |hmt_model| !validate_hmt_model(hmt_model) }
      @hmt_models = models
      !models.empty?
    end

    def validate_hmt_model(hmt_model)
      if !hmt_model.valid?
        logger.error hmt_model.error
        return false
      elsif !hmt_model.has_many_through?(class_name)
        logger.warning "Model #{hmt_model.name} does not contain a has_many through association for #{class_name}."
        return false
      end

      hmt_model.through_model = hmt_model.find_through_model(class_name) if hmt_model.through_model.nil?
      if !hmt_model.through_model.valid?
        logger.error hmt_model.through_model.error
        return false
      elsif !validate_parent_model(hmt_model, hmt_model.through_model.name, hmt_model.through_model)
        return false
      elsif !validate_child_model(hmt_model.through_model, class_name, view_only? ? model : nil)
        return false
      elsif !validate_child_model(hmt_model.through_model, hmt_model.name, nil)
        return false
      end
      true
    end

  end
end
