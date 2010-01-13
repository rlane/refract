require 'test/unit'
require 'refract'

class BasicTest < Test::Unit::TestCase
  def test_receive
    expected_msg = :foo
    received = false

    receiver = Refract::Actor.new 'receiver' do |me|
      msg = me.receive
      assert_equal expected_msg, msg
      received = true
    end

    receiver << expected_msg

    sched = Refract::Scheduler.new
    sched << receiver
    sched.run

    assert received
  end

  def test_ring
    sched = Refract::Scheduler.new
    n = 7
    initial_msg = 32
    c = 0
    a = []

    n.times do |i|
      a[i] = Refract::Actor.new i.to_s do |me|
        while true
          msg = me.receive
          msg -= 1 if msg > 0
          c += 1
          a[(i+1)%n] << msg
          break if msg == 0
        end
      end
      sched << a[i]
    end

    a[0] << initial_msg
    sched.run

    assert_equal 38, c
  end
end
