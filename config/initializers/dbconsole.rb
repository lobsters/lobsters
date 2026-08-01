module SneakWrapperIntoPath
  def find_cmd_and_exec(commands, *args)
    ENV["PATH"] = "#{Rails.root.join("bin")}#{File::PATH_SEPARATOR}#{ENV["PATH"]}"
    super
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::AbstractAdapter.singleton_class.prepend(SneakWrapperIntoPath)
end
