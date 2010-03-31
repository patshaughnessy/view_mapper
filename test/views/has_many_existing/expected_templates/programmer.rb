class Programmer < ActiveRecord::Base
  has_many :projects, :through => :assignments
  has_many :assignments
  accepts_nested_attributes_for :assignments,
                                :allow_destroy => true,
                                :reject_if => proc { |attrs|
                                  attrs['name'].blank? &&
                                  attrs['project_id'].blank?
                                }
end
