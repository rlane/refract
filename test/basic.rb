require 'rubygems'
require 'test/unit'
require 'eventmachine'
require 'refract'
require 'case'

class BasicTest < Test::Unit::TestCase
  def test_receive
    expected_msg = :foo
    received = false

    receiver = Refract::Actor.new 'receiver' do |me|
      msg = me.receive
      assert_equal expected_msg, msg
      received = true
    end

    sched = Refract::Scheduler.new
    sched << receiver

    EM.run_block do
      receiver << expected_msg
      sched.run
    end

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

    EM.run_block do
      a[0] << initial_msg
      sched.run
    end

    assert_equal 38, c
  end

  def test_block
    got = nil
    a = Refract::Actor.new 'blocker' do |me|
      got = me.receive
    end
    sched = Refract::Scheduler.new
    sched << a

    EM.run_block do
      sched.run
      a << :foo
    end

    assert_equal :foo, got
  end

  def test_filter
    results = []

    a = Refract::Actor.new 'consumer' do |me|
      results << me.receive
      me.receive { |f| f.when(Object) { |x| results << x } }
      results << me.receive(Symbol)
      me.receive String
      me.receive Integer
      me.receive do |f|
        f.when(String) { |x| fail }
        f.when(Symbol) { |x| results << x }
        f.when(Object) { |x| fail }
      end
      me.receive true
      results << :done
    end

    sched = Refract::Scheduler.new
    sched << a

    EM.run_block do
      sched.run
      [:foo, :bar, 1, :baz, 'string', :boo, true].each { |x| a << x }
    end
    assert_equal [:foo, :bar, :baz, :boo, :done], results
  end

  def test_timeout
    timed_out = false
    a = Refract::Actor.new 'waiter' do |me|
      me.receive do |f|
        f.after(1.0) { timed_out = true; EM.stop }
      end
    end

    sched = Refract::Scheduler.new
    sched << a

    EM.run { sched.run }
    assert_equal true, timed_out
  end

  def test_tcp_connect
    port = 3943

    a = Refract::Actor.new 'reverser' do |me|
      s = Refract.tcp '127.0.0.1', port, me
      while true
        me.receive do |f|
          f.when(Case[:data, s, String]) { |_,_,data| s << data.reverse }
          f.when(Case[:closed, s]) { |x| EM.stop }
          f.when(Object) { |x| fail "unexpected #{x.inspect}" }
        end
      end
    end

    sched = Refract::Scheduler.new
    sched << a

    $received = nil

    EM.run do
      EM.start_server '127.0.0.1', port do |c|
        c.send_data "reversible"

        def c.receive_data data
          $received = data
          EM.stop
        end
      end

      sched.run
    end

    assert_equal "reversible".reverse, $received
  end

  def test_tcp_server
    port = 3943

    a = Refract::Actor.new 'reverser' do |me|
      s = nil
      while true
        me.receive do |f|
          f.when(Case[:accept]) { |_,_,_s| s = _s  }
          f.when(Case[:data, s, String]) { |_,_,data| s << data.reverse }
          f.when(Case[:closed, s]) { |x| }
          f.when(Object) { |x| fail "unexpected #{x.inspect}" }
        end
      end
    end

    sched = Refract::Scheduler.new
    sched << a

    $received = nil

    EM.run do
      Refract.tcp_server 'localhost', port, a

      EM.connect '127.0.0.1', port do |c|
        c.send_data 'reversible'

        def c.receive_data data
          $received = data
          EM.stop
        end
      end

      sched.run
    end

    assert_equal 'reversible'.reverse, $received
  end
end
