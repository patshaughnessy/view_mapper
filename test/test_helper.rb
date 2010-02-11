require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_record'

ActiveRecord::Base.establish_connection({ :adapter => 'sqlite3', :database => ':memory:' })

require 'rails_generator'
require 'rails_generator/scripts'
require 'rails_generator/scripts/generate'

def add_source(path)
  Rails::Generator::Base.append_sources(Rails::Generator::PathSource.new(:builtin, path))
end
add_source(File.dirname(__FILE__) + '/../generators')
add_source(File.dirname(__FILE__) + '/generators')

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'view_mapper'
require 'views/fake/fake_view'

def setup_test_table(paperclip_columns = false)
  ActiveRecord::Base.connection.create_table :testies, :force => true do |table|
    table.column :first_name, :string
    table.column :last_name,  :string
    table.column :address,    :string
    table.column :some_flag,  :boolean
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

def setup_test_model(paperclip_columns = false)
  setup_test_table(paperclip_columns)
  Object.send(:remove_const, "Testy") rescue nil
  Object.const_set("Testy", Class.new(ActiveRecord::Base))
  Testy.class_eval do
    def self.attachment_definitions
      { :avatar => {:validations => []}, :avatar2 => {:validations => []} }
    end
  end
  ActiveRecord::Base.send(:include, MockPaperclip)
  ActionController::Base.send(:include, MockAutoComplete)
  Object.const_get("Testy")
end

def setup_parent_test_model(create_foreign_key = true, child_belongs_to_parent = true, parent_has_many_children = true)
  ActiveRecord::Base.connection.create_table :parents, :force => true do |table|
    table.column :name, :string
  end
  ActiveRecord::Base.connection.create_table :some_other_models, :force => true do |table|
    table.column :name,      :string
    table.column :parent_id, :integer
  end
  ActiveRecord::Base.connection.add_column :testies, :parent_id, :integer unless !create_foreign_key
  Object.send(:remove_const, "Parent") rescue nil
  Object.const_set("Parent", Class.new(ActiveRecord::Base))
  Object.send(:remove_const, "SomeOtherModel") rescue nil
  Object.const_set("SomeOtherModel", Class.new(ActiveRecord::Base))
  Parent.class_eval do
    has_many :testies
    has_many :some_other_models unless !parent_has_many_children
    def testies_attributes=
      'fake'
    end
    def some_other_models_attributes=
      'fake'
    end
  end
  Testy.class_eval do
    belongs_to :parent unless !child_belongs_to_parent
  end
  SomeOtherModel.class_eval do
    belongs_to :parent
    def parent_name
      'something'
    end
    def parent_name=
    end
  end
  Object.const_get("Parent")
end

def setup_second_parent_test_model(has_virtual_attribute_setter = true, has_virtual_attribute = true, has_foreign_key = true, parent_has_name_method = false, parent_has_name_column = true)
  ActiveRecord::Base.connection.create_table :second_parents, :force => true do |table|
    table.column :name, :string unless !parent_has_name_column
    table.column :other_field, :string
  end
  ActiveRecord::Base.connection.add_column :some_other_models, :second_parent_id, :integer unless !has_foreign_key
  Object.send(:remove_const, "SecondParent") rescue nil
  Object.const_set("SecondParent", Class.new(ActiveRecord::Base))
  SecondParent.class_eval do
    has_many :some_other_models
    def some_other_models_attributes=
      'fake'
    end
    def name
      'fake'
    end unless !parent_has_name_method
  end
  SomeOtherModel.class_eval do
    belongs_to :second_parent
    if has_virtual_attribute
      def second_parent_name
        'something'
      end
      def second_parent_other_field
        'something'
      end
    end
    if has_virtual_attribute_setter
      def second_parent_name=
        'something'
      end
      def second_parent_other_field=
        'something'
      end
    end
  end
end

def setup_test_model_without_nested_attributes
  ActiveRecord::Base.connection.create_table :third_models, :force => true do |table|
    table.column :name, :string
  end
  Object.send(:remove_const, "ThirdModel") rescue nil
  Object.const_set("ThirdModel", Class.new(ActiveRecord::Base))
  Parent.class_eval do
    has_many :third_model
  end
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

module ActionController
  class Base; end
end

module MockAutoComplete
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def auto_complete_for
    end
  end
end

def generator_cmd_line(gen, args, model)
  if gen == 'view_for'
    cmd_line = [model]
  else
    cmd_line = [model, 'first_name:string', 'last_name:string', 'address:string', 'some_flag:boolean']
  end
  (cmd_line << args).flatten
end

def generator_script_cmd_line(gen, args, model = 'testy')
  ([gen] << generator_cmd_line(gen, args, model)).flatten
end

def new_generator_for_test_model(gen, args, model = 'testy')
  Rails::Generator::Base.instance(gen, generator_cmd_line(gen, args, model))
end

def expect_no_actions
  Rails::Generator::Commands::Create.any_instance.expects(:directory).never
  Rails::Generator::Commands::Create.any_instance.expects(:template).never
  Rails::Generator::Commands::Create.any_instance.expects(:route_resources).never
  Rails::Generator::Commands::Create.any_instance.expects(:file).never
  Rails::Generator::Commands::Create.any_instance.expects(:route).never
  Rails::Generator::Commands::Create.any_instance.expects(:dependency).never
end

def expect_no_warnings
  Rails::Generator::Base.logger.expects(:error).never
  Rails::Generator::Base.logger.expects(:warning).never
  Rails::Generator::Base.logger.expects(:route).never
end

def stub_actions
  Rails::Generator::Commands::Create.any_instance.stubs(:directory)
  Rails::Generator::Commands::Create.any_instance.stubs(:template)
  Rails::Generator::Commands::Create.any_instance.stubs(:route_resources)
  Rails::Generator::Commands::Create.any_instance.stubs(:file)
  Rails::Generator::Commands::Create.any_instance.stubs(:route)
  Rails::Generator::Commands::Create.any_instance.stubs(:dependency)
end

def stub_warnings
  Rails::Generator::Base.logger.stubs(:error)
  Rails::Generator::Base.logger.stubs(:warning)
  Rails::Generator::Base.logger.stubs(:route)
end
