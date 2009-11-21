class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
<% for attribute in attributes -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>
<% for attachment in attachments -%>
      t.string   :<%= attachment %>_file_name
      t.string   :<%= attachment %>_content_type
      t.integer  :<%= attachment %>_file_size
      t.datetime :<%= attachment %>_updated_at
<% end -%>
<% unless options[:skip_timestamps] %>
      t.timestamps
<% end -%>
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
