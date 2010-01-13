module Refract

class Mailbox
  include Refract::Logging

  def initialize actor
    @messages = []
    @blocked = false
    @actor = actor
  end

  def << msg
    @messages << msg
    if @blocked
      @blocked = false
      @actor.wakeup
    end
  end

  def receive &block
    while true
      msg_index = @messages.find_index { |x| !block_given? || yield(x) }
      if msg_index
        l :received, @actor, @messages[msg_index]
        return @messages.delete_at(msg_index)
      else
        @blocked = true
        @actor.block
      end
    end
  end
end

end
