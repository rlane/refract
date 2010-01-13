module Refract

module Logging
  def l *a
    $stderr.puts(a.map { |x| Logging.format x } * ' ') if $VERBOSE
  end

  def self.format x
    case x
    when Symbol then x.to_s
    when Actor then "<#{x.name}>"
    else x.inspect
    end
  end
end

end
