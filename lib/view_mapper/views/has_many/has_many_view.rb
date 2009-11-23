module ViewMapper
  module HasManyView

    include HasManyChildModels

    def source_root_for_view
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def manifest
      m = super.edit do |action|
        action unless is_child_model_action?(action)
      end
      add_child_models_manifest(m)
      m
    end

    def validate
      super
      @valid &&= validate_child_models
    end

  end
end
