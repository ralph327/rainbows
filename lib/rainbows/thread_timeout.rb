# -*- encoding: binary -*-
require 'thread'

# Soft timeout middleware for thread-based concurrency models in \Rainbows!
# This timeout only includes application dispatch, and will not take into
# account the (rare) response bodies that are dynamically generated while
# they are being written out to the client.
#
# In your rackup config file (config.ru), the following line will
# cause execution to timeout in 1.5 seconds.
#
#    use Rainbows::ThreadTimeout, :timeout => 1.5
#    run MyApplication.new
#
# You may also specify a threshold, so the timeout does not take
# effect until there are enough active clients.  It does not make
# sense to set a +:threshold+ higher or equal to the
# +worker_connections+ \Rainbows! configuration parameter.
# You may specify a negative threshold to be an absolute
# value relative to the +worker_connections+ parameter, thus
# if you specify a threshold of -1, and have 100 worker_connections,
# ThreadTimeout will only activate when there are 99 active requests.
#
#    use Rainbows::ThreadTimeout, :timeout => 1.5, :threshold => -1
#    run MyApplication.new
#
# This middleware only affects elements below it in the stack, so
# it can be configured to ignore certain endpoints or middlewares.
#
# Timed-out requests will cause this middleware to return with a
# "408 Request Timeout" response.

class Rainbows::ThreadTimeout < Struct.new(:app, :timeout,
                                           :threshold, :watchdog,
                                           :active, :lock)

  # :stopdoc:
  class ExecutionExpired < ::Exception
  end

  def initialize(app, opts)
    timeout = opts[:timeout]
    Numeric === timeout or
      raise TypeError, "timeout=#{timeout.inspect} is not numeric"

    if threshold = opts[:threshold]
      Integer === threshold or
        raise TypeError, "threshold=#{threshold.inspect} is not an integer"
      threshold == 0 and
        raise ArgumentError, "threshold=0 does not make sense"
      threshold < 0 and
        threshold += Rainbows::G.server.worker_connections
    end
    super(app, timeout, threshold, nil, {}, Mutex.new)
  end

  def call(env)
    lock.synchronize do
      start_watchdog unless watchdog
      active[Thread.current] = Time.now + timeout
    end
    begin
      app.call(env)
    ensure
      lock.synchronize { active.delete(Thread.current) }
    end
    rescue ExecutionExpired
      [ 408, { 'Content-Type' => 'text/plain', 'Content-Length' => '0' }, [] ]
  end

  def start_watchdog
    self.watchdog = Thread.new do
      begin
        if next_wake = lock.synchronize { active.values }.min
          next_wake -= Time.now
          sleep(next_wake) if next_wake > 0
        else
          sleep(timeout)
        end

        # "active.size" is atomic in MRI 1.8 and 1.9
        next if threshold && active.size < threshold

        now = Time.now
        lock.synchronize do
          active.delete_if do |thread, time|
            time >= now and thread.raise(ExecutionExpired).nil?
          end
        end
      end while true
    end
  end
  # :startdoc:
end