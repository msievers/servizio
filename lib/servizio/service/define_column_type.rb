#
# In order to make service objects more compatible with simple_form, one should
# define column types for attributes, so that the input types can be determined
# by simple_form automatically. Simple include this into your service class.
#
# For a list of column types supported by rails have a look at
#
# http://stackoverflow.com/questions/3956186/where-is-the-documentation-page-for-activerecord-data-types
#
require_relative "../service"

module Servizio::Service::DefineColumnType
  def self.included(base)
    base.extend ClassMethods
    base.include InstanceMethods
  end

  def self.column_type_getter_name(attribute)
    "defined_column_type_for_#{attribute}"
  end

  module ClassMethods
    def define_column_type(attribute, type)
      define_method(Servizio::Service::DefineColumnType.column_type_getter_name(attribute)) do
        type.to_sym
      end
    end
  end

  module InstanceMethods
    def column_for_attribute(attribute)
      if has_attribute?(attribute)
        Struct.new(:limit, :name, :type).new(
          nil,
          attribute,
          send(Servizio::Service::DefineColumnType.column_type_getter_name(attribute))
        )
      end
    end

    def has_attribute?(attribute)
      respond_to?(Servizio::Service::DefineColumnType.column_type_getter_name(attribute))
    end
  end
end
