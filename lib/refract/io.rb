module Refract

def self.tcp host, port, controller
  EM.connect host, port, Reflector, controller
end

def self.tcp_server host, port, controller
  sig = EM.start_server host, port, Reflector, controller do |c|
    controller << [:accept, sig, c]
  end
end

def self.unix path, controller
  EM.connect path, Reflector, controller
end

def self.io io, controller
  EM.attach io, Reflector, controller
end

class Reflector < EventMachine::Connection
  include Refract::Logging
  attr_accessor :controller

  def initialize controller
    @controller = controller
  end

  def receive_data data
    l self, :data, data
    @controller << [:data, self, data]
  end

  def unbind
    l self, :closed
    @controller << [:closed, self]
  end

  def << data
    l self, :<<, data
    send_data data
  end
end

end
