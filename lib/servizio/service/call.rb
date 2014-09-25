# http://gshutler.com/2013/04/ruby-2-module-prepend
module Servizio::Service::Call
  def call
    run_callbacks :call do
      if authorized? && valid?
        @called = true
        self.result = super
      else
        @called = false
        true # in order for run_callbacks to run
      end
    end
  end

  def call!
    call
    self
  end
end
