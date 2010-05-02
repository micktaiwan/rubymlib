require "test/unit"
require 'aibmanager'

class TokenizerTest < Test::Unit::TestCase
  
  def setup
    super
    @m = AIBManager.new
  end
  
  def test_versions
    v = @m.versions
    assert(v.class.to_s == "Array", "version is not an array")
    assert(v.size > 0, "no versions found")
 end
  
end
