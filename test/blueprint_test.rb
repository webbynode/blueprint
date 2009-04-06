require 'test_helper'

module Kernel
 
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    $stdout = STDOUT
    return out
  end
 
end

class BlueprintTest < Test::Unit::TestCase
  def test_missing_email
    out = capture_stdout do 
      b = blueprint "Test", :item_type => "readystack" do |f|
        f.provides "rails", :script => "script.sh"
      end
    end
    
    assert out.string.include?("no email template found for rails")
  end
end
