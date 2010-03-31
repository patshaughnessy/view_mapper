class <%= class_name %> < ActiveRecord::Base
<% has_many_through_models.each do |hmt_model| -%>
<% attribs = Array.new(hmt_model.through_model.attributes) -%>
<% attribs << hmt_model.through_model.foreign_key_for(hmt_model.name) -%>
  has_many :<%= hmt_model.name.underscore.pluralize %>, :through => :<%= hmt_model.through_model.name.underscore.pluralize %>
  has_many :<%= hmt_model.through_model.name.underscore.pluralize %>
  accepts_nested_attributes_for :<%= hmt_model.through_model.name.underscore.pluralize %>,
                                :allow_destroy => true<% if attribs.size > 0 %>,<% end %>
<% if attribs.size > 0 -%>
<% if attribs.size == 1 -%>
                                :reject_if => proc { |attrs| attrs['<%= attribs[0].name %>'].blank? }
<% elsif -%>
                                :reject_if => proc { |attrs|
<% attribs.each_with_index do |attr, i| -%>
                                  attrs['<%= attr.name %>'].blank?<% unless i == attribs.size-1 %> &&<% end %>
<% end -%>
                                }
<% end -%>
<% end -%>
<% end -%>
end
