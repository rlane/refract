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

  def test_block
    got = nil
    a = Refract::Actor.new 'blocker' do |me|
      got = me.receive
    end
    sched = Refract::Scheduler.new
    sched << a
    sched.run
    a << :foo
    sched.run
    assert_equal :foo, got
  end

  def test_filter
    got = nil

    a = Refract::Actor.new 'consumer' do |me|
      got = me.receive
      me.receive { |f| f.when(Object) { |x| got = x } }
      got = me.receive Symbol
      me.receive String
      me.receive Integer
      me.receive do |f|
        f.when(String) { |x| fail }
        f.when(Symbol) { |x| got = x }
        f.when(Object) { |x| fail }
      end
      me.receive true
      got = :done
    end

    sched = Refract::Scheduler.new
    sched << a

    sendit = lambda do |msg,expect|
      a << msg
      sched.run
      assert_equal expect, got
    end

    sendit[:foo, :foo]
    sendit[:bar, :bar]
    sendit[1, :bar]
    sendit[:baz, :baz]
    sendit['string', :baz]
    sendit[:boo, :boo]
    sendit[true, :done]
  end
end
