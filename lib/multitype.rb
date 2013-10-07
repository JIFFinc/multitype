require "active_support/core_ext/class/attribute"
require "multitype/version"
require "awesome_print"

module Multitype

  class NoTypeError < NoMethodError; end
  class NoTypeCatError < NoTypeError; end
  class NoTypeSetError < NoTypeError; end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Return the multitype data from the cache
  [:comparators, :typesets].each do |method|
    __send__(:define_method, "get_multitype_#{method}") do |type|
      __get_multitype_cache__(type, method)
    end
  end

  # Forward this method to the class method
  def __get_multitype_cache__(*args)
    self.class.__get_multitype_cache__(*args)
  end

  module ClassMethods

    def type_comparator(type, *comparators)
      new_comparators = comparators.inject({}) do |out, comparator|
        if comparator.is_a?(Hash)
          out.merge(comparator)
        else
          out.merge({comparator => comparator})
        end
      end

      __send__(:attr_accessor, *new_comparators.keys)
      __create_multitype_datastore__

      # Get the type name if a typeset is passed as an object
      type = type.type if type.is_a?(Object) && type.respond_to?(:__multitype_typeset__)

      # Append to the list comparator columns
      __update_multitype_cache__(type, :comparators, new_comparators)
    end

    def type_alias(type, *aliases)
      __create_multitype_datastore__

      # Get the type name if a typeset is passed as an object
      type = type.type if type.is_a?(Object) && type.respond_to?(:__multitype_typeset__)
      raise NoTypeError, type.to_s unless __get_multitype_cache__(type)

      aliases.each do |_alias|
        alias_method _alias, type
      end
    end

    def type_accessor(type, *columns)
      __create_multitype_datastore__

      # Add accessors to the typeset that is passed or any typesets matching type
      if type.is_a?(Object) && type.respond_to?(:__multitype_typeset__)
        type.class.__send__(:attr_accessor, *columns)
      else
        raise NoTypeError, type.to_s unless __get_multitype_cache__(type)
        raise NoTypeSetError, type.to_s unless __get_multitype_cache__(type, :typesets)
        __get_multitype_cache__(type, :typesets).each do |name, typeset|
          typeset.class.attr_accessor(*columns)
        end
      end
    end

    def deftype(type, name, args = {}, &block)
      __create_multitype_datastore__
      type = type.to_sym
      name = name.to_sym

      # Merge in name, type and model for accessable access
      args.merge!(type: type, name: name, model: self)

      # Get the list of accessable keys we need
      accessable = args.keys.map(&:to_sym)

      # Kickstart the type comparators
      type_comparator(type)

      # Get the name of the class to extend if it exists
      type_class = if args[:class]
        klass = if args[:class].is_a?(String)
          get_const(args[:class])
        else
          args[:class]
        end

        klass.is_a?(Object) ? klass : Object
      else
        Object
      end

      # Define the class and mark as a typeset
      object = Class.new(type_class)
      object.class_attribute :__multitype_typeset__
      object.__multitype_typeset__ = true

      # Execute the passed block as if it was class level code
      object.class_exec(&block) if block_given?

      # Instantiate the object
      object = object.new

      # Make the variables passed accessable
      type_accessor(object, *accessable)

      # Set the instance attributes that were passed in
      args.each { |key, val| object.__send__("#{key}=", val) }

      # Add the type to the multitype cache
      __update_multitype_cache__(type, :typesets, {name => object})

      # Create the accessor method if it does not exist
      unless self.respond_to?(type)
        self.__send__(:define_method, type) do
          use_typeset = nil # Object to return

          # Loop through the types to find the one to use
          __get_multitype_cache__(type, :typesets).each do |name, typeset|
            match = true # Did we find a match

            # Loop through the type comparators to find a match
            __get_multitype_cache__(type, :comparators).each do |model_comparator, typeset_comparator|

              # Check the comparator for a match
              match = if typeset.respond_to?(typeset_comparator) && self.respond_to?(model_comparator)
                typeset.__send__(typeset_comparator) == self.__send__(model_comparator)
              else
                false
              end

              # If we fail at least one
              # match then break the loop
              break unless match
            end

            # If we have a match,
            # stop looking for one
            if match
              use_typeset = typeset
              break
            end
          end

          # Return the typeset
          use_typeset
        end
      end

      object
    end

    def __get_multitype_cache__(type = nil, cat = nil, klass = self.name.to_sym, depth = 0)
      type = type.to_sym if type
      cat  = cat.to_sym  if cat

      # If the klass is not cached just return nil
      return nil unless __multitype_cache__[klass]

      # Return the level of data requested
      result = if type.nil? && cat.nil?
        __multitype_cache__[klass]
      elsif cat.nil? && __multitype_cache__[klass]
        __multitype_cache__[klass][type]
      elsif __multitype_cache__[klass] && __multitype_cache__[klass][type]
        __multitype_cache__[klass][type][cat]
      else
        nil
      end

      # Don't loop through ancestors on lower objects
      return result if depth > 0

      # Iterate over ancestors to use their typesets
      ancestors.inject(result) do |out, ancestor|
        ancestor = ancestor.name.to_sym

        # Skip if ancestor is self or Multitype
        if ancestor == klass || ancestor == 'Multitype'
          out
        else

          # Get data lower down the ancestry tree
          merge_in = __get_multitype_cache__(type, cat, ancestor, depth + 1)

          # Merge in data as required
          if out.nil? && ! merge_in.nil?
            merge_in
          else
            if merge_in.is_a?(Array)
              out.concat(merge_in)
            elsif merge_in.is_a?(Hash)
              out.merge(merge_in)
            else
              out
            end
          end
        end
      end
    end

    private

    def __update_multitype_cache__(type, cat, data)
      klass = self.name.to_sym
      type  = type.to_sym
      cat   = cat.to_sym

      # Create the hashes if they don't exist
      __multitype_cache__[klass] ||= {}
      __multitype_cache__[klass][type] ||= {}
      __multitype_cache__[klass][type][cat] ||= data

      # Merge in the data for hashes
      if data.is_a?(Hash)
        data = __multitype_cache__[klass][type][cat].merge(data)
        __multitype_cache__[klass][type][cat] = data
      end

      # Concatanate the data for arrays
      if data.is_a?(Array)
        data = __multitype_cache__[klass][type][cat].concat(data).uniq
        __multitype_cache__[klass][type][cat] =  data
      end

      __multitype_cache__[klass]
    end

    def __create_multitype_datastore__
      if ! self.respond_to?(:__multitype_cache__)
        class_attribute :__multitype_cache__
        self.__send__(:__multitype_cache__=, {})
        true
      else
        false
      end
    end
  end
end

