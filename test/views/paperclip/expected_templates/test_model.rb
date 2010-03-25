class TestModel < ActiveRecord::Base
  has_attached_file :avatar
  has_attached_file :avatar2
end
