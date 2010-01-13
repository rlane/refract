module Refract

class Actor
  include Refract::Logging
  attr_accessor :scheduler

  def initialize name
    @mailbox = []
    @name = name

    callcc { |cc| @cc = cc; return }

    fail "not attached to a scheduler" unless @scheduler
    yield self

    @cc = nil
    @scheduler.switch
  end

  def yield
    l :yield, self
    @scheduler << self
    callcc { |cc| @cc = cc; @scheduler.switch }
  end

  def resume
    l :resume, self
    @cc.call
  end

  def << msg
    l :send, self, msg
    @mailbox << msg
  end

  def receive
    while true
      msg_index = @mailbox.find_index { |x| !block_given? || yield(x) }
      if msg_index
        l :received, self, @mailbox[msg_index]
        return @mailbox.slice!(msg_index)
      else
        l :blocked, self
        self.yield
      end
    end
  end

  def inspect
    "<#{@name}>"
  end
end

end
