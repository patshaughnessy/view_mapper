require 'ftools'
require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'activerecord'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(config['test'])

require 'rails_generator'
require 'rails_generator/scripts'
require 'rails_generator/scripts/generate'

Rails::Generator::Base.reset_sources
def add_source(path)
  Rails::Generator::Base.append_sources(Rails::Generator::PathSource.new(:builtin, path))
end

add_source(File.dirname(__FILE__) + '/../generators')
add_source(File.dirname(__FILE__) + '/rails_generator/generators/components')
add_source(File.dirname(__FILE__))

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'view_mapper'
require 'fake_view'

def setup_test_table(paperclip_columns = false)
  ActiveRecord::Base.connection.create_table :testies, :force => true do |table|
    table.column :first_name, :string
    table.column :last_name,  :string
    table.column :address,    :string
    if paperclip_columns
      table.column :avatar_file_name,     :string
      table.column :avatar_content_type,  :string
      table.column :avatar_file_size,     :integer
      table.column :avatar_updated_at,    :datetime
      table.column :avatar2_file_name,    :string
      table.column :avatar2_content_type, :string
      table.column :avatar2_file_size,    :integer
      table.column :avatar2_updated_at,   :datetime
    end
  end
end

def setup_test_model(missing_columns = false)
  setup_test_table(missing_columns)
  Object.send(:remove_const, "Testy") rescue nil
  Object.const_set("Testy", Class.new(ActiveRecord::Base))
  Testy.class_eval do
    def self.attachment_definitions
      { :avatar => {:validations => []}, :avatar2 => {:validations => []} }
    end
  end
  ActiveRecord::Base.send(:include, MockPaperclip)
  Object.const_get("Testy")
end

module MockPaperclip
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def has_attached_file
      end
    end
  end
end

class Rails::Generator::NamedBase
  public :attributes
end

def generator_cmd_line(gen, args)
  if gen == 'view_for'
    cmd_line = ['testy']
  else
    cmd_line = ['testy', 'first_name:string', 'last_name:string', 'address:string']
  end
  (cmd_line << args).flatten
end

def generator_script_cmd_line(gen, args)
  ([gen] << generator_cmd_line(gen, args)).flatten
end

def new_generator_for_test_model(gen, args)
  Rails::Generator::Base.instance(gen, generator_cmd_line(gen, args))
end
