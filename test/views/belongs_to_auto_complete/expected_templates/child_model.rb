class ChildModel < ActiveRecord::Base
  belongs_to :parent_model
  belongs_to :second_parent_model
  def parent_model_name
    parent_model.name if parent_model
  end
  def parent_model_name=(name)
    self.parent_model = ParentModel.find_by_name(name)
  end
  def second_parent_model_other_field
    second_parent_model.other_field if second_parent_model
  end
  def second_parent_model_other_field=(other_field)
    self.second_parent_model = SecondParentModel.find_by_other_field(other_field)
  end
end
