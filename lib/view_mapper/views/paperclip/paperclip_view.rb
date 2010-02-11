module ViewMapper
  module PaperclipView

    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/templates")
    end

    def source_roots_for_view
      [ PaperclipView.source_root, File.expand_path(source_root), File.join(self.class.lookup('model').path, 'templates') ]
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
        model.attachments
      else
        []
      end
    end

    def parse_attachments_from_param
      view_param.split(',')
    end

    def validate
      @valid = validate_attachments
      @valid &&= super
    end

    def validate_attachments
      if !paperclip_installed
        logger.error "The Paperclip plugin does not appear to be installed."
        return false
      elsif attachments.empty?
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
        if !model.has_attachment?(attachment)
          logger.error "Attachment '#{attachment}' does not exist."
          return false
        elsif !model.has_columns_for_attachment?(attachment)
          logger.error model.error
          return false
        end
      end
      true
    end

    def paperclip_installed
      ActiveRecord::Base.methods.include?('has_attached_file') ||
      ActiveRecord::Base.methods.include?(:has_attached_file)
    end

  end
end
