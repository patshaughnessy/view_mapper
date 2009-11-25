module ViewMapper
  module HasManyView

    include HasManyChildModels

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [ HasManyView.source_root, File.expand_path(source_root), File.join(self.class.lookup('model').path, 'templates') ]
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
