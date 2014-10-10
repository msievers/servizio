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

      # since the result influences if the callbacks are triggered or not
      # we always return self and the user can/has to call .result on it
      self
    end
  end

  def call!
    call
  end
end
