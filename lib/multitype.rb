require "active_support/core_ext/class/attribute"
require "multitype/version"

module Multitype
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def type_dependents(type, *columns)
      __send__(:attr_accessor, *columns)

      # Create class attribute for storing dependent info
      if ! self.respond_to?("#{type}_type_dependents")
        class_attribute "#{type}_type_dependents"
        self.__send__("#{type}_type_dependents=", [])
      end

      # Append to the list of columsn to check for when
      # accessing a type by its attribute name
      dependents = self.__send__("#{type}_type_dependents")
      dependents.concat(columns)
      self.__send__("#{type}_type_dependents=", dependents)
      dependents
    end

    def deftype(type, name, args = {}, &block)

      # Merge in name and type for accessable
      args.merge!(:type => type, :name => name)

      # Delete triggers unless they are in array format
      args.delete(:triggers) if ! args[:triggers].is_a?(Array)

      # Get the list of accessable keys we need
      accessable = args.keys.map(&:to_sym)

      # Save for use in the typeclass
      parent = self

      # Create class attribute hashes
      if ! self.respond_to?("#{type}_types_by_name")
        class_attribute "#{type}_types_by_name".to_sym,
                        "#{type}_types_by_trigger".to_sym

        self.send("#{type}_types_by_name=", {})
        self.send("#{type}_types_by_trigger=", {})
      end

      # Create type dependents array
      type_dependents(type)

      # Get the name of the class to define
      type_class = if args[:class]
        klass = if args[:class].is_a?(String)
          get_const(args[:class])
        else
          args[:class]
        end

        klass.is_a?(Class) ? klass : Object
      else
        Object
      end

      # Define the class with the methods within
      object = Class.new(type_class)
      object.class_exec(parent, &block) if block_given?

      # Instantiate the object
      object = object.new

      # Make the variables passed accessable
      object.class.__send__(:attr_accessor, *accessable)

      # Set the instance variables
      args.each { |key, val| object.__send__("#{key}=", val) }

      # Add the type to the class attribute hash
      # Duplicate so subclasses dont alter parent
      types = self.__send__("#{type}_types_by_name").dup
      types[name.to_sym] = object
      self.__send__("#{type}_types_by_name=", types)

      # Add the triggers to the class attribute hash
      if object.respond_to?(:triggers)
        triggers = self.__send__("#{type}_types_by_trigger")

        object.triggers.each do
          triggers[trigger] ||= []
          triggers[trigger]  << type
        end

        self.__send__("#{type}_types_by_trigger=", triggers)
      end

      # Create the accessor method if it does not exist
      if ! self.respond_to?(type)
        self.__send__(:define_method, type) do
          use_object = nil # Object to return

          # Loop through the types to find the one to use
          self.__send__("#{type}_types_by_name").each do |name, obj|
            match = true # Did we find a match

            # Loop through the type dependent attributes
            self.__send__("#{type}_type_dependents").each do |dep|

              match = if obj.respond_to?(dep) && self.respond_to?(dep)
                obj.__send__(dep) == self.__send__(dep)
              else
                false
              end

              # If we fail on a match stop looping
              break unless match
            end

            # If we found a match use it
            if match
              use_object = obj
              break
            end
          end

          # Return the type or nil
          use_object
        end
      end

      object
    end
  end
end

