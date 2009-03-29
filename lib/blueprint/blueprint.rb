require "rubygems"
require "utils"
require "yaml"
require "pp"

module BlueprintComponents
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
  include BlueprintComponents

  creates "value" do |args, opts|
    { :content => args.pop }.merge(opts)
  end
end

class Parameter < Component
  include BlueprintComponents

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
  include BlueprintComponents
  
  creates "aggregate" do |args, opts|
    { :label => args.pop }.merge(opts)
  end
end

class Dependency < Component
  include BlueprintComponents

  creates "dependency" do |args, opts|
    { :content => args.pop }.merge(opts)
  end
end

class Blueprint
  include Doodle::Utils
  include BlueprintComponents
  
  def initialize(blueprint_def)
    @def = blueprint_def
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

def blueprint(*args, &block)
  blueprint_def = args.last.is_a?(Hash) ? args.pop : {}
  blueprint = Blueprint.new(blueprint_def)
  
  if block_given?
    yield blueprint
  end
  
  blueprint
end