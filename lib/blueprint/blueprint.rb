require "rubygems"
require "doodle"
require "yaml"
require "pp"

module FormulaComponents
  def parameter(*args, &block)
    param = Parameter.new(*args)
    yield param if block_given?
    add_child param
  end
  
  def dependency(*args, &block)
    dep = Dependency.new(*args)
    yield dep if block_given?
    add_child dep
  end
  
  def no_op(*args, &block)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    dependency nil, { :label => args.pop }.merge(opts)
  end
  
  def aggregate(*args, &block)
    aggregate = Aggregate.new(*args)
    yield aggregate if block_given?
    add_child aggregate
  end
  
  def definition
    @def
  end
  
  module_function
  
  def add_child(control)
    (@def[:children] ||= []) << control.definition
    control
  end
end

class Component
  class << self
    attr_accessor :item_type
    attr_accessor :block
  end
  
  def self.creates(*args, &block)
    self.item_type = args.pop
    if block_given?
      self.block = block
    end
  end
  
  def attributes(*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    @def.merge!(opts)
  end

  def initialize(*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    @def = { :item_type => self.class.item_type }.merge(opts)
    if self.class.block
      @def.merge!(self.class.block.call(args, opts))
    end
  end
end

class Value < Component
  include FormulaComponents

  creates "value" do |args, opts|
    { :content => args.pop }.merge(opts)
  end
end

class Parameter < Component
  include FormulaComponents

  def value(*args)
    val = Value.new(*args)
    unless val.definition[:label]
      val.definition[:label] = val.definition[:content]
    end
    add_child val
  end  
  
  creates "param" do |args, opts|
    { :content => args.pop }.merge(opts)
  end
end

class Aggregate < Component
  include FormulaComponents
  
  creates "aggregate" do |args, opts|
    { :label => args.pop }.merge(opts)
  end
end

class Dependency < Component
  include FormulaComponents

  creates "dependency" do |args, opts|
    { :content => args.pop }.merge(opts)
  end
end

class Formula
  include Doodle::Utils
  include FormulaComponents
  
  def initialize(formula_def)
    @def = formula_def
  end
  
  def provides(*args)
    opts = args.last.is_a?(Hash) ? args.pop : nil
    s = (@def[:content] = args.pop)
    
    if opts
      @def.merge!(opts)
      
    else
      @def[:script] = "#{s}.sh"
      @def[:email] = "#{s}.markdown"
      
    end
    
    (errors ||= []) << "provides requires an argument" unless @def.has_key?(:email)
    (errors ||= []) << "no email template found for #{@def[:content]}" unless @def.has_key?(:email)
    (errors ||= []) << "no script found for #{@def[:content]}" unless @def.has_key?(:script)
    
    raise "Errors: #{errors * ", "}" if errors
  end
  
  def requires(req)
    if req.is_a?(Hash)
      requirement_def = { :group => req[:group], :contains => req[:with] }
    else
      requirement_def = { :group => req, :contains => req }
    end
    
    (@def[:dependencies] ||= []) << requirement_def
  end
  
  def attributes(attrs)
    @def[:attributes] = attrs
  end
  
  def outputs(attrs)
    @def[:output_params] = attrs
  end
  
  def to_yaml
    stringify_keys(@def, true).to_yaml
  end
end

def desc(s)
  @desc = s
end

def formula(*args, &block)
  formula_def = args.last.is_a?(Hash) ? args.pop : {}
  formula = Formula.new(formula_def)
  
  if block_given?
    yield formula
  end
  
  formula
end

rails = formula(:type => "stack", :name => "rails") do |f|
  f.provides "rails"
  
  f.parameter "version", :label => "Rails Version", :render_as => "combobox" do |p|
    p.value "2.3.2"
    p.value "2.2.2"
    p.value "2.1.2"
  end
  
  f.parameter "doc_rdoc", :label => "Install rdoc", :render_as => "checkbox"
  f.parameter "doc_ri",   :label => "Install ri",   :render_as => "checkbox"
  
  f.parameter "create-dummyapp", 
    :label => "Create dummy app?", 
    :render_as => "checkbox",
    :attributes => {:default => "y"}
  f.parameter "dummyapp-path", 
    :label => "Path for dummy app",
    :render_as => "text",
    :attributes => {
      "required"         => "y",
      "default"          => "/var/rails",
      "validation"       => "^((?:\/[a-zA-Z0-9]+(?:_[a-zA-Z0-9]+)*(?:\-[a-zA-Z0-9]+)*)+)$",
      "validation_error" => "Use a valid path without an ending slash (ie, <code>/var/www</code>)"
    }
    
  f.parameter "dummyapp-database", 
    :label => "Database for dummy app", 
    :render_as => "combobox" do |p|
      
      p.value "sqlite3", :label => "SQLite 3"
      p.value "mysql", :label => "MySQL"
      p.value "sqlite2", :label => "SQLite 2"
      p.value "postgresql", :label => "PostgreSQL"
    
  end
end

rails_rs = formula(:type => "readystack", :name => "rs.rails") do |f|
  # this formula delivers "rs.rails"
  f.provides "rs.rails"
  
  # dependencies and order of execution -- top => bottom
  # apache2/ngnix, mysql/postgre, passenger/mongrel
  f.requires :group => "webservers", 
             :with => ["apache2", "nginx"]
  f.requires :group => "database",   
             :with => ["mysql-server", "postgresqlserver"]
  f.requires "rails"
  f.requires :group => "proxy",      
             :with => ["passenger", "mongrel_cluster"]
  
  # attributes
  f.attributes :required => 'y'
  f.outputs    :installed_gems => "^Installed following gems: (.*)",
               :success_indicator => "^SUCCESS: (.*)"
  
  # always installs rails
  f.dependency "rails", :render_as => "hidden"

  # gives two webserver/proxy combo options:
  # apache2 + passenger or nginx + mongrel
  f.parameter "webserver-proxy", :label => "WebServer and Proxy" do |p|
    p.attributes :required => "y"

    p.aggregate "Apache2 and Passenger", :render_as => "radio" do |agr|
      agr.dependency "apache2"
      agr.dependency "passenger"
    end
    
    p.aggregate "Nginx and Mongrel Cluster", :render_as => "radio" do |agr|
      agr.dependency "nginx"
      agr.dependency "mongrel_cluster"
    end
    
    # doesn't install webserver/proxy
    p.aggregate "No webserver & proxy", :render_as => "radio" do |agr|
      agr.parameter "-"
    end
  end
  
  # database options: mysql or postgresql
  f.parameter "database-server", :label => "Database Server" do |p|
    p.attributes :required => "y"
    
    p.dependency "mysql-server",     :label => "MySQL",      :render_as => "radio"
    p.dependency "postgresqlserver", :label => "PostgreSQL", :render_as => "radio"
    p.no_op      "No database server", :render_as => "radio"
  end
  
  # list of gems
  f.aggregate "Additional Gems" do |agr|
    %w{will_paginate thoughtbot-paperclip 
      rspec authlogic hpricot capistrano}.each do |gem|
        
        agr.parameter "gem_#{gem}", :label => gem, :render_as => "checkbox"
        
    end
  end
end

puts rails_rs.to_yaml
puts
puts rails.to_yaml

