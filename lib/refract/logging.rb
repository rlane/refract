module Refract

module Logging
  def l *a
    $stderr.puts(a.map { |x| x.inspect } * ' ') if $VERBOSE
  end
end

end
