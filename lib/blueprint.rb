require 'blueprint/blueprint'
require 'blueprint/components'
require 'blueprint/utils'

def blueprint(*args, &block)
  blueprint_def = args.last.is_a?(Hash) ? args.pop : {}
  blueprint = Blueprint.new(blueprint_def)
  
  if block_given?
    yield blueprint
  end
  
  blueprint
end