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

def setup_test_model
  unless Object.const_defined?("Testy")
    Object.const_set("Testy", Class.new(ActiveRecord::Base)) 
    ActiveRecord::Base.connection.create_table :testies, :force => true do |table|
      table.column :first_name, :string
      table.column :last_name,  :string
      table.column :address,    :string
    end
  end
  Object.const_get("Testy")
end

class Rails::Generator::NamedBase
  public :attributes
end
