module TempPool
  class Worker
    attr_accessor :thread, :messages

    def self.create(pool)
      pool.register(self.new(pool).thread)
    end

    def initialize(pool)
      @pool = pool
      @messages = Queue.new
      @thread = Thread.new do
        Thread.current[:worker] = self

        catch(:exit) do
          begin
            loop do
              work, args = begin
                             @messages.pop(true)
                           rescue ThreadError => e
                             @pool.queue.pop
                           end
              perform(work, args)
            end
          rescue => e
            puts e.inspect
            puts Thread.current.backtrace
            @pool.results.push(nil)
          end
        end
      end
    end

    def shutdown
      @messages.push([proc{ |exit| throw(exit) }, :exit])
    end

  private

    def perform(work, args)
      @pool.results.push(work.call(*args))
    end
  end
end
