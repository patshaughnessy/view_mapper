module ViewMapper
  module BelongsToView

    include BelongsToParentModels

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [ BelongsToView.source_root, File.expand_path(source_root), File.join(self.class.lookup('model').path, 'templates') ]
    end

    def validate
      super
      @valid &&= validate_parent_models
    end

  end
end
