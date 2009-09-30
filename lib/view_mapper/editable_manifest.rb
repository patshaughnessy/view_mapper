class EditableManifest < Rails::Generator::Manifest

  def edit
    @actions = @actions.collect do |action|
      yield action
    end.compact
    return self
  end

end
