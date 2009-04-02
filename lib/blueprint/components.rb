require "blueprint/utils"

module BlueprintComponents
  BLUEPRINT_TRANSLATIONS = {
    :render_as => :control,
    :type => :item_type
  }
  
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
      @def.merge!(:attributes => opts)
    end

    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      
      if opts
        opts.clone.keys.each do |k|
          if BLUEPRINT_TRANSLATIONS.key?(k)
            opts[BLUEPRINT_TRANSLATIONS[k]] = opts.delete(k)
          end
        end
      end
      
      @def = { :item_type => self.class.item_type }.merge(opts)
      if self.class.block
        @def.merge!(self.class.block.call(self, args, opts))
      end
    end
    
    def remove_attribute(attr)
      @def.delete(attr)
    end
  end

  class Value < Component
    include BlueprintComponents

    creates "value" do |obj, args, opts|
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

    creates "param" do |obj, args, opts|
      content = args.pop

      if opts.key?(:values)
        opts.delete(:values)

        values = obj.remove_attribute(:values)
        unless values.is_a?(Array)
          raise "values should be an array for Parameter #{content}"
        end
        
        values.each { |v| obj.value(v) }
      end
      
      { :content => content }.merge(opts)
    end
  end

  class Aggregate < Component
    include BlueprintComponents

    creates "aggregate" do |obj, args, opts|
      { :label => args.pop }.merge(opts)
    end
  end

  class Dependency < Component
    include BlueprintComponents

    creates "dependency" do |obj, args, opts|
      { :content => args.pop }.merge(opts)
    end
  end

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
