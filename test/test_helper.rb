require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_record'
require 'class_factory'

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

ClassFactory.define :test_model do |t|
  t.string  :first_name
  t.string  :last_name
  t.string  :address
  t.boolean :some_flag
end

ClassFactory.define :parent_model, :class_eval => 'has_many :child_models' do |parent|
  parent.string :name
end

ClassFactory.define :second_parent_model, :class_eval => 'has_many :child_models' do |parent|
  parent.string :name
  parent.string :other_field
end

child_model_code = <<END
  belongs_to :parent_model
  def parent_model_name
    'something'
  end
  def parent_model_name=
  end

  belongs_to :second_parent_model
  def second_parent_model_name
    'something else'
  end
  def second_parent_model_name=
  end
END

ClassFactory.define :child_model, :class_eval => child_model_code do |child|
  child.string  :name
  child.integer :parent_model_id
  child.integer :second_parent_model_id
end

second_child_model_code = <<END
  belongs_to :parent_model
  def parent_model_name
    'something'
  end
  def parent_model_name=
  end
END

ClassFactory.define :second_child_model, :class_eval => second_child_model_code do |child|
  child.integer :parent_model_id
  child.string  :first_name
  child.string  :last_name
  child.string  :address
  child.boolean :some_flag
end

has_many_through_code = <<SRC
has_many :programmers, :through => :assignments
has_many :assignments
SRC
ClassFactory.define :project, :class_eval => has_many_through_code do |t|
  t.string :name
end

has_many_through_code = <<SRC
has_many :projects, :through => :assignments
has_many :assignments
def assignments_attributes=
  'fake'
end
SRC
ClassFactory.define :programmer, :class_eval => has_many_through_code do |t|
  t.string :name
end

through_model_code = <<SRC
belongs_to :project
belongs_to :programmer
def project_name
  'something'
end
def project_name=
end
SRC
ClassFactory.define :assignment, :class_eval => through_model_code do |a|
  a.integer :project_id
  a.integer :programmer_id
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

def generator_script_cmd_line(gen, args, model = 'test_model')
  ([gen] << generator_cmd_line(gen, args, model)).flatten
end

def new_generator_for_test_model(gen, args, model = 'test_model')
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
