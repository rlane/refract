module Refract

class Scheduler
  include Refract::Logging
  attr_reader :runqueue

  def initialize
    @runqueue = []
    @cc = nil
    @tickled = false
  end

  def << actor
    l :scheduler, :<<, actor
    actor.scheduler = self
    @runqueue << actor
    tickle
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

  def tickle
    if !@tickled
      @tickled = true
      EM.next_tick { @tickled = false; run }
    end
  end
end

end
