
module Network

  def drb_init
    DRb.start_service
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
      puts e if rescue_me
      raise e unless rescue_me
    end

    def read_all template, timeout=0, rescue_me=true
      @ts.read_all(template)
    rescue Exception => e
      puts e if rescue_me
      raise e unless rescue_me
    end

    def take template, timeout=0, rescue_me=true
      @ts.take(template, timeout)
    rescue TypeError => e
      puts "Bad format in JobSpace"
      puts e
      puts e.backtrace
    rescue Exception => e
      puts e if rescue_me
      raise e unless rescue_me
    end

  end

  module Writer

    def write *args
      @ts.write(*args)
    end

  end
end
