require 'openssl'

class Utils

  def self.repeat_every(interval)
    Thread.new do
      loop do
        start_time = Time.now
        yield
        elapsed = Time.now - start_time
        sleep([interval - elapsed, 0].max)
      end
    end
  end

  def self.random_str(len=15)
    str = ""
    while str.length < len
      chr = ::OpenSSL::Random.random_bytes(1)
      ord = chr.unpack('C')[0]
      if (ord >= 48 && ord <= 57) || (ord >= 65 && ord <= 90) || (ord >= 97 && ord <= 122)
        str += chr
      end
    end
    return str
  end

  def self.find_tuplespace opts
    # todo move this out
    require 'drb'
    require 'rinda/ring'
    #DRb.current_server rescue DRb.start_service
    server = opts[:server] if opts
    ts = nil
    if server
      ts = DRbObject.new_with_uri(server)
    else
      ts = Rinda::RingFinger.primary
      lookup = ['<broadcast>', 'localhost']
      finger = Rinda::RingFinger.new(lookup)
      ts = finger.primary
    end
    raise "Couldn't find TS" unless ts
    ts
  end
end
