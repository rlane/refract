module Refract

class Actor
  include Refract::Logging
  attr_accessor :scheduler

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
    l :yield, self
    @scheduler << self
    switch_out
  end

  def resume
    l :resume, self
    @cc.call
  end

  def sleep
    l :sleep, self
    switch_out
  end

  def wakeup
    l :wakeup, self
    @scheduler << self
  end

  def << msg
    l :send, self, msg
    @mailbox << msg
  end

  def receive &block
    @mailbox.receive(&block)
  end

  def inspect
    "<#{@name}>"
  end
end

end
