
module Network

  def drb_init
    require 'socket'
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? }
    if ip
      raise "IPV4 only supported" unless ip.ip? and ip.ipv4?
      ip = ip.ip_address
    else
      ip = ""
    end
    DRb.start_service("druby://#{ip}:0")
  end

  def drb_close
    DRb.stop_service
  end

  def find_tuplespace opts
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

  module Reader

    def read template, timeout=0, rescue_me=true
      @ts.read(template, timeout)
    rescue Exception => e
      puts e unless e.class == Rinda::RequestExpiredError
      raise e unless rescue_me
    end

    def read_all template, timeout=0, rescue_me=true
      @ts.read_all(template)
    rescue Exception => e
      puts e unless e.class == Rinda::RequestExpiredError
      raise e unless rescue_me
    end

    def take template, timeout=0, rescue_me=true
      @ts.take(template, timeout)
    rescue TypeError => e
      puts "Bad format in JobSpace"
      puts e
      puts e.backtrace
    rescue Exception => e
      puts e unless e.class == Rinda::RequestExpiredError
      raise e unless rescue_me
    end

  end

  module Writer

    def write *args
      @ts.write(*args)
    end

  end
end
