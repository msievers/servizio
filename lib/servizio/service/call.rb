# http://gshutler.com/2013/04/ruby-2-module-prepend
module Servizio::Service::Call
  def call
    run_callbacks :call do
      if authorized? && valid?
        @called = true
        self.result = super
      else
        @called = false
      end
    end
  end

  def call!
    call
    self
  end
end
