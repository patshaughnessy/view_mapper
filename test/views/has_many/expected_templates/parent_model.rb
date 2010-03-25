class ParentModel < ActiveRecord::Base
  has_many :child_models
  has_many :second_child_models
  accepts_nested_attributes_for :child_models,
                                :allow_destroy => true,
                                :reject_if => proc { |attrs| attrs['name'].blank? }
  accepts_nested_attributes_for :second_child_models,
                                :allow_destroy => true,
                                :reject_if => proc { |attrs|
                                  attrs['first_name'].blank? &&
                                  attrs['last_name'].blank? &&
                                  attrs['address'].blank? &&
                                  attrs['some_flag'].blank?
                                }
end
