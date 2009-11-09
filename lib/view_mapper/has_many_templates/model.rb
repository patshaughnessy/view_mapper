class <%= class_name %> < ActiveRecord::Base
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
<% child_models.each do |child_model| -%>
  has_many :<%= child_model.name.underscore.pluralize %>
<% end -%>
<% child_models.each do |child_model| -%>
  accepts_nested_attributes_for :<%= child_model.name.underscore.pluralize %>,
                                :allow_destroy => true<% if child_model.attributes.size > 0 %>,<% end %>
<% if child_model.attributes.size > 0 -%>
<% if child_model.attributes.size == 1 -%>
                                :reject_if => proc { |attrs| attrs['<%= child_model.attributes[0].name %>'].blank? }
<% elsif -%>
                                :reject_if => proc { |attrs|
<% child_model.attributes.each_with_index do |attr, i| -%>
                                  attrs['<%= attr.name %>'].blank?<% unless i == child_model.attributes.size-1 %> &&<% end %>
<% end -%>
                                }
<% end -%>
<% end -%>
<% end -%>
end
