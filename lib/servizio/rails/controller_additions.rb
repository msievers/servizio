module Servizio::Rails::ControllerAdditions
  def self.call_operation(operation, context = nil, options = {})
    # use cancan(can) ability if present
    operation.ability = options[:ability]

    Servizio::Service.class_variable_get(:@@states).each do |state|
      state_handler_setter = operation.method("once_on_#{state}")
      state_handler =
      if options["on_#{state}"]
        options["on_#{state}"]
      elsif context.respond_to?(method_name = "handle_operation_#{state}", true)
        context.method(method_name)
      end

      if state_handler.present?
        state_handler_setter.call -> (op) do
          if state_handler.is_a?(Hash)
            if state_handler[:flash].present?
              state_handler[:flash].each_pair { |key, value| context.flash[key] = value }
            end

            if (path_or_url = handler[:redirect_to]).present?
              context.redirect_to path_or_url
            elsif (path_or_url = handler[:render]).present?
              context.render path_or_url
            end
          elsif state_handler.is_a?(Proc)
            state_handler.call(op) 
          end
        end
      end
    end

    operation.call
  end

  # only this method is actually mixed in by include
  def call_operation(operation, options = {})
    options.reverse_merge!({
      ability: options[:ability] || (respond_to?(:current_ability) ? current_ability : nil)
    })

    Servizio::Rails::ControllerAdditions.call_operation(operation, self, options)
  end
end
