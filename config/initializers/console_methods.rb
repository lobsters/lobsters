module Rails
  module ConsoleMethods
    def admin
      User.find_by! username: 'pushcx'
    end
  end
end
