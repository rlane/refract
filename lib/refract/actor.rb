module Refract

class Actor
  include Refract::Logging
  attr_accessor :scheduler
  attr_reader :name

  def initialize name
    @mailbox = Refract::Mailbox.new self
    @name = name

    callcc { |cc| @cc = cc; return }

    fail "not attached to a scheduler" unless @scheduler
    yield self

    @cc = nil
    @scheduler.switch
  end

  def switch_out
    callcc { |cc| @cc = cc; @scheduler.switch }
  end

  def yield
    l :actor, self, :yield
    @scheduler << self
    switch_out
  end

  def resume
    l :actor, self, :resume
    @cc.call
  end

  def sleep
    l :actor, self, :sleep
    switch_out
  end

  def wakeup
    l :actor, self, :wakeup
    @scheduler << self
  end

  def << msg
    l :actor, self, :<<, msg
    @mailbox << msg
  end

  def receive default_matcher=Object, &block
    @mailbox.receive(default_matcher, &block)
  end
end

end
