class SomeOtherModel < ActiveRecord::Base
  belongs_to :parent
  belongs_to :second_parent
  def parent_name
    parent.name if parent
  end
  def parent_name=(name)
    self.parent = Parent.find_by_name(name)
  end
  def second_parent_other_field
    second_parent.other_field if second_parent
  end
  def second_parent_other_field=(other_field)
    self.second_parent = SecondParent.find_by_other_field(other_field)
  end
end
