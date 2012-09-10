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
    DRb.start_service
    ts = Rinda::RingFinger.primary
    lookup = ['<broadcast>', 'localhost']
    server = opts["server"]
    if server
      lookup << server
    end
    finger = Rinda::RingFinger.new(lookup)
    ts = finger.primary
    if ts.nil?
      ts = DRbObject.new_with_uri(server)
    end
    raise "Couldn't find TS" unless ts
    ts
  end
end
