class SomeOtherModel < ActiveRecord::Base
  belongs_to :parent
  belongs_to :second_parent
  def parent_name
    parent.name if parent
  end
  def second_parent_name
    second_parent.name if second_parent
  end
end
