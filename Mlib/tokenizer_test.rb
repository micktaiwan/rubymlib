require "test/unit"
require 'tokenizer'

class TokenizerTest < Test::Unit::TestCase
  
  def setup
    super
    @w = Tokenizer.new
  end
  
  def test_basic
    arr = @w.parse("test")
    assert(arr.size == 1, "word count failed (1)")
    assert(arr[0] == "test", "test failed (2)")
    arr = @w.parse("je m'appelle 23eme msg--- et, oui. abat-jour abat--jour")
    assert(arr[0] == "je", "test failed (4)")
    assert(arr[1] == "m'", "test failed (5)")
    assert(arr[2] == "appelle", "test failed (6)")
    assert(arr[3] == "eme", "test failed (7)")
    assert(arr[4] == "msg", "test failed (8)")
    assert(arr[5] == "et", "test failed (9)")
    assert(arr[6] == "oui", "test failed (10)")
    assert(arr[7] == "abat-jour", "test failed (11)")
    assert(arr[8] == "abat", "test failed (12)")
    assert(arr[9] == "jour'", "test failed (13)")
 end
  
end
