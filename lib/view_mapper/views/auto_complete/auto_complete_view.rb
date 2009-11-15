module ViewMapper
  module AutoCompleteView

    def source_root_for_view
      File.dirname(__FILE__) + "/templates"
    end

    def manifest
      manifest = super
      if @valid
        manifest.route :name       => 'connect',
                       :path       => auto_complete_for_method,
                       :controller => controller_file_name,
                       :action     => auto_complete_for_method
      end
      manifest
    end

    def auto_complete_for_method
      "auto_complete_for_#{singular_name}_#{auto_complete_attribute}"
    end

    def auto_complete_attribute
      view_param
    end

    def validate
      super
      @valid &&= validate_auto_complete_attribute
    end

    def validate_auto_complete_attribute
      if auto_complete_attribute.nil?
        logger.error "No auto_complete attribute specified."
        return false
      elsif attributes.find { |a| a.name == auto_complete_attribute }.nil?
        logger.error "Field '#{auto_complete_attribute}' does not exist."
        return false
      end
      true
    end

  end
end
