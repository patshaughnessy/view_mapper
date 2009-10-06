module ViewMapper
  module PaperclipView

    def source_root_for_view
      File.dirname(__FILE__) + "/paperclip_templates"
    end

    def manifest
      m = super.edit do |action|
        action unless is_model_dependency_action(action) || !valid
      end
      unless view_only? || !valid
        add_model_actions(m)
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

    def attachments
      if view_param
        parse_attachments_from_param
      elsif view_only?
        inspect_model_for_attachments
      else
        []
      end
    end

    def parse_attachments_from_param
      view_param.split(',')
    end

    def inspect_model_for_attachments
      if model.respond_to?('attachment_definitions') && model.attachment_definitions
        model.attachment_definitions.keys.collect { |name| name.to_s }.sort
      else
        []
      end
    end

    def validate
      @valid = validate_attachments
      @valid &&= super
    end

    def validate_attachments
      if !paperclip_installed
        logger.error "The Paperclip plugin does not appear to be installed."
        return false
      elsif attachments == []
        if view_only?
          logger.warning "No paperclip attachments exist on the specified class."
        else
          logger.warning "No paperclip attachments specified."
        end
        return false
      else
        !attachments.detect { |a| !validate_attachment(a) }
      end
    end

    def validate_attachment(attachment)
      if view_only?
        if !has_attachment(attachment.to_sym)
          logger.error "Attachment '#{attachment}' does not exist."
          return false
        elsif !has_columns_for_attachment(attachment)
          return false
        end
      end
      true
    end

    def has_attachment(attachment)
      model.attachment_definitions && model.attachment_definitions.has_key?(attachment)
    end

    def has_columns_for_attachment(attachment)
      !paperclip_columns_for_attachment(attachment).detect { |paperclip_col| !has_column_for_attachment(attachment, paperclip_col) }
    end

    def has_column_for_attachment(attachment, paperclip_col)
      has_column = model.columns.collect { |col| col.name }.include?(paperclip_col)
      if !has_column
        logger.error "Column \'#{paperclip_col}\' does not exist. First run script/generate paperclip #{name} #{attachment}."
      end
      has_column
    end

    def built_in_columns
      attachments.inject(super) do |result, element|
        result + paperclip_columns_for_attachment(element)
      end
    end

    def paperclip_columns_for_attachment(attachment)
      %w{ file_name content_type file_size updated_at }.collect do |col|
        "#{attachment}_#{col}"
      end
    end

    def paperclip_installed
      ActiveRecord::Base.methods.include? 'has_attached_file'
    end

  end
end
