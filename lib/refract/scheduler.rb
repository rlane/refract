module Refract

class Scheduler
  include Refract::Logging
  attr_reader :runqueue

  def initialize
    @runqueue = []
    @cc = nil
  end

  def << actor
    l :scheduler, :<<, actor
    actor.scheduler = self
    @runqueue << actor
  end

  def switch
    @cc.call if runqueue.empty?
    actor = runqueue.shift
    actor.resume
  end

  def run
    callcc do |cc|
      @cc = cc
      switch
    end
  end
end

end
