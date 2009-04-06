require 'pp'
require "blueprint/components"
require "blueprint/utils"
require "yaml"

class Blueprint
  include Utils
  include BlueprintComponents
  
  def initialize(s)
    if s.is_a?(Hash)
      @def = s
    else
      @def[:label] = s
    end
  end
  
  def provides(*args)
    opts = args.last.is_a?(Hash) ? args.pop : nil
    s = (@def[:content] = args.pop)
    
    if opts
      @def.merge!(opts)
      
    else
      @def[:content] ||= s
      @def[:script] = "#{s}.sh"
      @def[:email] = "#{s}.markdown" if @def[:item_type] == "readystack"
      @def[:item_type] ||= "stack"
      
    end
    
    (errors ||= []) << "provides requires the blueprint name" if @def.empty?
    (errors ||= []) << "no blueprint name found" unless @def.has_key?(:content)
    (errors ||= []) << "no script found for #{@def[:content]}" unless @def.has_key?(:script)
    
    if @def[:item_type] == "readystack" and not @def[:email]
      (warnings ||= []) << "no email template found for #{@def[:content]}"
    end
    
    puts "Warning: #{warnings * ", "}" if warnings
    raise "Errors: #{errors * ", "}" if errors
  end
  
  def requires(req)
    if req.is_a?(Hash)
      requirement_def = { :group => req[:group], :contains => req[:with] }
    else
      requirement_def = { :group => req, :contains => [req] }
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