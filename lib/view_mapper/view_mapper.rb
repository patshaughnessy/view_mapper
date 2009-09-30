module ViewMapper

  def initialize(runtime_args, runtime_options = {})
    Rails::Generator::Commands::Base.class_eval { include RouteAction::Base }
    Rails::Generator::Commands::Create.class_eval { include RouteAction::Create }
    Rails::Generator::Commands::Destroy.class_eval { include RouteAction::Destroy }
    super
    if options[:view]
      self.extend(view_class)
      @source_root = source_root_for_view
    end
  end

  def view_class
    "ViewMapper::#{view_name.camelize}View".constantize
  end

  def view_name
    options[:view].split(':')[0]
  end

  def view_param
    options[:view].split(':')[1]
  end

  def add_options!(opt)
    opt.on("--view name", String, "Specify a view to generate") do |name|
      options[:view] = name
    end
    super
  end

end
