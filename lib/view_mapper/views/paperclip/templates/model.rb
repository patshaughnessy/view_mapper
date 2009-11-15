class <%= class_name %> < ActiveRecord::Base
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
<% for attachment in attachments -%>
  has_attached_file :<%= attachment %>
<% end -%>
end
