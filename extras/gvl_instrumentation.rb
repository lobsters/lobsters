require "gvl_timing"

class GvlInstrumentation
  def initialize(app, log_file)
    @app = app
    @log_file = log_file
    @log_file.sync = true
  end

  def call(env)
    response = nil

    before_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    before_gc_time = GC.total_time
    timer = GVLTiming.measure do
      response = @app.call(env)
    end
    total_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - before_time
    gc_time = GC.total_time - before_gc_time

    data = {
      gc_ms: (gc_time / 1_000_000.0).round(2),
      run_ms: (timer.cpu_duration * 1_000.0).round(2),
      idle_ms: (timer.idle_duration * 1_000.0).round(2),
      stall_ms: (timer.stalled_duration * 1_000.0).round(2),
      io_percent: (timer.idle_duration / total_time * 100.0).round(1),
      method: env["REQUEST_METHOD"]
    }
    if (controller = env["action_controller.instance"])
      data[:action] = "#{controller.controller_path}##{controller.action_name}"
    end

    @log_file.puts(JSON.generate(data))

    response
  end
end
