module TempPool
  class Pool
    attr_accessor :queue, :workers, :results

    def initialize(size=nil)
      @size = size
      @queue = Queue.new
      @workers = ThreadGroup.new
      @results = Queue.new
      @scheduled_count = 0

      @size.to_i.times do
        Worker.create(self)
      end
    end

    def register(worker)
      @workers.add(worker)
    end

    def schedule(*args, &block)
      @scheduled_count+=1
      add_worker unless @size
      @queue.push([block, *args])
      self
    end

    def value
      @value ||= begin
        Array.new(@scheduled_count) do
          @results.pop
        end.flatten.compact
      end
    end

    def add_worker
      Worker.create(self)
    end

    def remove_worker
      @workers.list.last[:worker].shutdown unless worker_count.zero?
    end

  private

    def worker_count
      @workers.list.count
    end
  end
end
