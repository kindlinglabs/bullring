require 'test_helper'

class BullringTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Bullring
  end
  
  test "bullring_runs" do
    begin
      Bullring.isAlive?
    rescue SystemExit
    end
    
    puts "Pre"
    sleep(10.0)
    puts "Post"
    
    while !Bullring.isAlive?
      puts 'not alive'
      sleep(1)
    end
  end
end
