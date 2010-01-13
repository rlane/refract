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

  def receive &block
    while true
      msg_index = @messages.find_index { |x| !block_given? || yield(x) }
      if msg_index
        l :received, @actor, @messages[msg_index]
        return @messages.delete_at(msg_index)
      else
        @sleeping = true
        @actor.sleep
      end
    end
  end
end

end
