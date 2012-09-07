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
end
