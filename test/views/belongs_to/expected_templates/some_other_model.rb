class SomeOtherModel < ActiveRecord::Base
  belongs_to :parent
  belongs_to :second_parent
  def parent_name
    parent.name if parent
  end
  def second_parent_other_field
    second_parent.other_field if second_parent
  end
end
