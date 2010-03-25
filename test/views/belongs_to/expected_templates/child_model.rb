class ChildModel < ActiveRecord::Base
  belongs_to :parent_model
  belongs_to :second_parent_model
  def parent_model_name
    parent_model.name if parent_model
  end
  def second_parent_model_other_field
    second_parent_model.other_field if second_parent_model
  end
end
