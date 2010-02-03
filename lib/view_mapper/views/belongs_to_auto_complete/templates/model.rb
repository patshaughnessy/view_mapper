class <%= class_name %> < ActiveRecord::Base
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
<% for parent_model in parent_models -%>
  belongs_to :<%= parent_model.name.underscore %>
<% end -%>
<% for parent_model in parent_models -%>
  def <%= parent_model.name.underscore %>_name
    <%= parent_model.name.underscore %>.name if <%= parent_model.name.underscore %>
  end
<% end -%>
end
