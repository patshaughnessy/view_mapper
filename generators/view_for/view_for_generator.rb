class ViewForGenerator < ScaffoldGenerator

  attr_reader   :columns
  attr_reader   :model

  BUILT_IN_COLUMNS = [ 'id', 'created_at', 'updated_at' ]

  def initialize(runtime_args, runtime_options = {})
    super
    @columns = []
    @model = find_model @name
    @columns = inspect_model_columns model unless model.nil?
  end

  def find_model(model_name)
    model = nil
    begin
      model = Object.const_get model_name.camelize
      if !model.new.kind_of? ActiveRecord::Base
        logger.error "Class '#{model_name}' is not an ActiveRecord::Base."
        model = nil
      end
    rescue NameError
      logger.error "Class '#{model_name}' does not exist."
    rescue ActiveRecord::StatementInvalid
      logger.error "Table for model '#{model_name}' does not exist - run rake db:migrate first."
    end
    model
  end

  def inspect_model_columns(model_object)
    model_object.columns.reject do |col|
      BUILT_IN_COLUMNS.include? col.name
    end
  end

  def manifest
    record do |m|
      if valid
        # Check for class naming collisions.
        m.class_collisions("#{controller_class_name}Controller", "#{controller_class_name}Helper")

        # Controller, helper, views, test and stylesheets directories.
        m.directory(File.join('app/controllers', controller_class_path))
        m.directory(File.join('app/helpers', controller_class_path))
        m.directory(File.join('app/views', controller_class_path, controller_file_name))
        m.directory(File.join('app/views/layouts', controller_class_path))
        m.directory(File.join('test/functional', controller_class_path))
        m.directory(File.join('test/unit/helpers', class_path))
        m.directory(File.join('public/stylesheets', class_path))

        for action in scaffold_views
          m.template(
            "view_#{action}.html.erb",
            File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb")
          )
        end

        # Layout and stylesheet.
        m.template('layout.html.erb', File.join('app/views/layouts', controller_class_path, "#{controller_file_name}.html.erb"))
        m.template('style.css', 'public/stylesheets/scaffold.css')

        m.template(
          'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
        )

        m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
        m.template('helper.rb',          File.join('app/helpers',     controller_class_path, "#{controller_file_name}_helper.rb"))
        m.template('helper_test.rb',     File.join('test/unit/helpers',    controller_class_path, "#{controller_file_name}_helper_test.rb"))

        m.route_resources controller_file_name
      end
    end
  end

  def valid
    !model.nil?
  end

  protected

    def banner
      "View generator usage TBD"
    end

    def attributes
      @attributes ||= attributes_from_columns(columns)
    end

    def attributes_from_columns(cols)
      cols.collect do |col|
        Rails::Generator::GeneratedAttribute.new col.name, col.type
      end
    end

    def add_options!(opt)
    end

end
