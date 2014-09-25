require "servizio/version"

module Servizio
  require_relative "./servizio/service"
  module Rails
    require_relative "./servizio/rails/controller_additions"
  end
end
