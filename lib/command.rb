module Firts
  class Worker
    class Command
      # Should return something runable
      def self.load(*args)
        p args
        cmd = args[0][0]['cmd']
        a = Struct.new('Command', :id, :runnable) do
          def run_cmd *args
            runnable.call *args
          end
        end
        a.new cmd, get_runnable(cmd)
      end

      def self.process *arg
        return *arg
      end

      def self.get_runnable cmd
        runnable = case cmd.to_sym
        when :shutdown
          self.method(:shutdown)
        when :status
          self.method(:status)
        else
          self.method(:blank)
        end
        runnable
      end

      # Executor methods
      def self.blank(*args); end

      def self.shutdown worker
        worker.cleanup(false)
      end

      def self.status worker
        worker.status
      end
    end
  end
end
