module ViewMapper
  module AutoCompleteView

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def manifest
      manifest = super
      if @valid
        auto_complete_attributes.each do |attrib|
          manifest.route :name       => 'connect',
                         :path       => auto_complete_for_method(attrib),
                         :controller => controller_file_name,
                         :action     => auto_complete_for_method(attrib)
        end
      end
      manifest
    end

    def auto_complete_for_method(attrib)
      "auto_complete_for_#{singular_name}_#{attrib}"
    end

    def auto_complete_attributes
      if view_param
        parse_auto_complete_attributes_from_param
      elsif view_only?
        model.text_fields
      else
        []
      end
    end

    def parse_auto_complete_attributes_from_param
      view_param.split(',')
    end

    def validate
      super
      @valid &&= validate_auto_complete_attributes
    end

    def validate_auto_complete_attributes
      if !auto_complete_installed
        logger.error "The auto_complete plugin does not appear to be installed."
        return false
      elsif auto_complete_attributes.empty?
        if view_only?
          logger.error "No text fields exist in the specified class."
        else
          logger.error "No auto_complete attribute specified."
        end
        return false
      else
        !auto_complete_attributes.detect { |a| !validate_auto_complete_attribute(a) }
      end
    end

    def validate_auto_complete_attribute(attrib_name)
      attrib = attributes.find { |a| a.name == attrib_name }
      if attrib.nil?
        logger.error "Field '#{attrib_name}' does not exist."
        return false
      elsif !ModelInfo.is_text_field_attrib_type? attrib.type
        logger.error "Field '#{attrib_name}' is not a text field."
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
