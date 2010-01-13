module Refract

class Mailbox
  include Refract::Logging

  def initialize actor
    @messages = []
    @sleeping = false
    @actor = actor
  end

  def << msg
    @messages << msg
    if @sleeping
      @sleeping = false
      @actor.wakeup
    end
  end

  def receive default_matcher, &block
    block ||= lambda { |f| f.when(default_matcher) { |x| x } }
    filter = Refract::Filter.new(@actor, &block)
    while true
      msg_index, matcher, action = filter.apply @messages
      if msg_index == :timeout
        return action[]
      elsif msg_index
        l :actor, @actor, :received, matcher, @messages[msg_index]
        return action[@messages.delete_at(msg_index)]
      else
        @sleeping = true
        @actor.sleep
      end
    end
  end
end

class Filter
  def initialize actor
    @actor = actor
    @branches = []
    @deadline = nil
    @deadline_action = nil
    yield self if block_given?
  end

  def when matcher, &action
    @branches << [matcher, action]
  end

  def after interval, &block
    fail "only one timeout may be specified" if @deadline
    @deadline = Time.now + interval
    @deadline_action = block
    EM.add_timer(interval) { @actor.wakeup }
  end

  def apply msgs
    return :timeout, @deadline, @deadline_action if @deadline && @deadline <= Time.now
    msgs.each_with_index do |msg,i|
      @branches.each do |m,a|
        return i,m,a if m === msg
      end
    end
    nil
  end
end

end
