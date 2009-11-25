module ViewMapper

  def initialize(runtime_args, runtime_options = {})
    Rails::Generator::Commands::Base.class_eval { include RouteAction::Base }
    Rails::Generator::Commands::Create.class_eval { include RouteAction::Create }
    Rails::Generator::Commands::Destroy.class_eval { include RouteAction::Destroy }
    super
    self.extend(view_module) if options[:view]
  end

  def source_path(relative_source)
    if options[:view]
      source_roots_for_view.map do |source_root|
        File.join(File.expand_path(source_root), relative_source)
      end.detect do |path|
        File.exists? path
      end
    else
      super
    end
  end

  def source_roots_for_view
    [ view_module.source_root, File.expand_path(source_root) ]
  end

  def view_module
    "ViewMapper::#{view_name.camelize}View".constantize
  end

  def view_name
    options[:view].split(':')[0]
  end

  def view_param
    options[:view].split(':')[1]
  end

  def view_only?
    self.respond_to?(:model)
  end

  def add_options!(opt)
    opt.on("--view name", String, "Specify a view to generate") do |name|
      options[:view] = name
    end
    super
  end

end
