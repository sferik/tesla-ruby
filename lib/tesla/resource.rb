# frozen_string_literal: true

require_relative "deep_copy"
require_relative "errors/invalid_response"

module Tesla
  # Base class for objects that wrap Tesla Fleet API responses
  #
  # The endpoints answer with the resources the library defines, which declare their readers with {.attribute},
  # {.predicate}, {.time_attribute}, {.resource_attribute}, and {.resource_list_attribute}, and declare what they
  # inspect with and what identifies them with {.inspect_with} and {.identified_by}. Those declarations are private,
  # since no endpoint answers with a resource of your own, so they can change within 0.x; the readers they declare,
  # {.attribute_names}, and the rest of the instance interface are public.
  #
  # @api public
  class Resource
    include DeepCopy

    # The raw attributes from the API response
    # @api public
    # @return [Hash{String => Object}] the raw attributes
    # @example Get the raw attributes
    #   vehicle.attributes["vin"]
    attr_reader :attributes

    # Build a list of resources from a list of attribute hashes
    #
    # @api public
    # @param list [Array<Hash{String, Symbol => Object}>] the attribute hashes
    # @return [Array<Resource>] the resources
    # @example Build a list of vehicles
    #   Tesla::Vehicle.list(JSON.parse(body).fetch("response"))
    def self.list(list)
      list.map { |attributes| new(attributes) } #: Array[instance]
    end

    # The macros that declare the readers of a resource, extended into {Resource}
    # @api private
    module Declaration
      # Define a reader for an attribute
      #
      # Endpoints spell some fields differently, so a reader may declare several keys and reads the first
      # one the response contains.
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
      # @return [Symbol] the name of the reader
      # @example Declare a reader
      #   attribute :name
      def attribute(name, *keys)
        keys = keys_for(name, keys)
        define_method(name) do
          # @type self: Resource
          value_of(keys)
        end
        record_attribute(name)
      end

      # Define a predicate for a boolean attribute
      #
      # @api private
      # @param name [Symbol] the name of the attribute (the reader is suffixed with a question mark)
      # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
      # @return [Symbol] the name of the reader
      # @example Declare a predicate for a boolean field
      #   predicate :in_service
      def predicate(name, *keys)
        keys = keys_for(name, keys)
        define_method(:"#{name}?") do
          # @type self: Resource
          !!value_of(keys)
        end
        record_attribute(:"#{name}?")
      end

      # Define a reader that reads a timestamp attribute as a Time
      #
      # The Fleet API writes a timestamp as the milliseconds since the Unix epoch. The reader raises {InvalidResponse}
      # when the attribute is not a number of them.
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
      # @return [Symbol] the name of the reader
      # @example Declare a reader that parses a timestamp field
      #   time_attribute :timestamp
      def time_attribute(name, *keys)
        keys = keys_for(name, keys)
        define_method(name) do
          # @type self: Resource
          value = value_of(keys)
          value && parse_time(value)
        end
        record_attribute(name)
      end

      # Define a reader that wraps a nested object in a resource
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @param resource_class [Class<Resource>] the resource the nested object is wrapped in
      # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
      # @return [Symbol] the name of the reader
      # @example Declare a reader that wraps a nested object
      #   resource_attribute :charge_state, ChargeState
      def resource_attribute(name, resource_class, *keys)
        keys = keys_for(name, keys)
        define_method(name) do
          # @type self: Resource
          value = value_of(keys)
          value && resource_class.new(value)
        end
        record_attribute(name)
      end

      # Define a reader that wraps each of a list of nested objects in a resource
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @param resource_class [Class<Resource>] the resource each nested object is wrapped in
      # @param keys [Array<String, Symbol>] the attribute keys, most preferred first (defaults to the name)
      # @return [Symbol] the name of the reader
      # @example Declare a reader that wraps a list of nested objects
      #   resource_list_attribute :superchargers, ChargingSite
      def resource_list_attribute(name, resource_class, *keys)
        keys = keys_for(name, keys)
        define_method(name) do
          # @type self: Resource
          resource_class.list(value_of(keys) || [])
        end
        record_attribute(name)
      end

      # The names of the readers the class declares
      #
      # These are the readers declared with attribute, predicate, time_attribute, resource_attribute, and
      # resource_list_attribute, and a pattern matches a resource by these names (see {#deconstruct_keys}).
      #
      # A subclass of a resource inherits the readers its superclass declared, until it declares readers of its own.
      #
      # @api public
      # @return [Array<Symbol>] the reader names, in the order they were declared
      # @example
      #   Tesla::User.attribute_names # => [:email, :full_name, :profile_image_url]
      def attribute_names
        @attribute_names || (superclass.attribute_names if superclass.respond_to?(:attribute_names)) || [] # steep:ignore NoMethod
      end

      private

      # Record a declared reader for {.attribute_names}
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @return [Symbol] the name of the reader
      def record_attribute(name)
        @attribute_names = [*attribute_names, name]
        name
      end

      # The attribute keys a reader reads
      #
      # @api private
      # @param name [Symbol] the name of the reader
      # @param keys [Array<String, Symbol>] the declared keys
      # @return [Array<String>] the keys, most preferred first
      def keys_for(name, keys)
        (keys.empty? ? [name] : keys).map(&:to_s)
      end
    end

    extend Declaration

    # Declare which readers appear in the inspect output
    #
    # @api private
    # @param readers [Array<Symbol>] the readers to show
    # @return [Array<Symbol>] the readers to show
    # @example Declare the readers a resource inspects with
    #   inspect_with :vin, :display_name
    def self.inspect_with(*readers)
      @inspect_readers = readers
    end

    # The readers shown in the inspect output
    #
    # @api private
    # @return [Array<Symbol>] the readers to show, inherited from the superclass until the class declares its own
    # @example
    #   Tesla::Vehicle.inspect_readers # => [:vin, :display_name, :state]
    def self.inspect_readers
      @inspect_readers || (superclass.inspect_readers if superclass.respond_to?(:inspect_readers)) || [] # steep:ignore NoMethod
    end

    # Declare which readers identify the resource
    #
    # Resources with an identity compare equal when those readers match, even if other attributes differ.
    #
    # @api private
    # @param readers [Array<Symbol>] the identifying readers
    # @return [Array<Symbol>] the identifying readers
    # @example Declare what identifies a resource
    #   identified_by :vin
    def self.identified_by(*readers)
      @identity_readers = readers
    end

    # The readers that identify the resource
    #
    # @api private
    # @return [Array<Symbol>] the identifying readers, inherited from the superclass until the class declares its
    #   own, and empty when the resource is identified by all of its attributes
    # @example
    #   Tesla::Vehicle.identity_readers # => [:vin]
    def self.identity_readers
      @identity_readers || (superclass.identity_readers if superclass.respond_to?(:identity_readers)) || [] # steep:ignore NoMethod
    end

    # Initialize a new resource
    #
    # The attributes are deeply copied and frozen, so resources are immutable values and the hash passed in
    # stays mutable. Symbol keys are converted to strings, at every level.
    #
    # @api public
    # @param attributes [Hash{String, Symbol => Object}] the raw attributes from the API response
    # @return [Resource] a new instance
    # @example Wrap a parsed response
    #   Tesla::Vehicle.new(JSON.parse(body).fetch("response"))
    def initialize(attributes)
      @attributes = deep_freeze(attributes)
    end

    # Read a raw attribute
    #
    # @api public
    # @param key [String, Symbol] the attribute key
    # @return [Object, nil] the attribute value
    # @example Read an attribute that has no reader
    #   vehicle[:tokens]
    def [](key)
      attributes[key.to_s]
    end

    # Convert the resource to a hash
    #
    # The hash is a copy the caller owns and may change, as the hash `to_h` answers with elsewhere in Ruby is, and
    # so is everything nested in it: the hashes, arrays, and strings a resource holds are frozen, so they are copied
    # rather than handed to the caller to raise `FrozenError` on. {#attributes} answers with the frozen hash itself,
    # for reading it without the copy.
    #
    # @api public
    # @return [Hash{String => Object}] a copy of the raw attributes
    # @example Convert a vehicle to a hash
    #   vehicle.to_h
    # @example Add a field of your own to the copy
    #   vehicle.to_h.merge!("fetched_at" => Time.now)
    # @example Change a field nested in the copy
    #   data.to_h["charge_state"]["fetched_at"] = Time.now
    def to_h
      deep_dup(attributes) #: Hash[String, untyped]
    end

    # The attributes a pattern asks for, read by the declared readers
    #
    # A resource matches a `case`/`in` pattern by the names in {.attribute_names}, read as the readers read them, so
    # a pattern sees a timestamp as a `Time` and a boolean as a predicate such as `in_service?`.
    #
    # A name whose reader raises {InvalidResponse}, such as a timestamp that is not a number, is left out rather than
    # raised from: a pattern asking for it does not match, and one asking for the rest of the attributes, such as
    # `in {vin:, **rest}`, matches without it. Reading that reader still raises, so a caller that asks for the
    # attribute is told why it cannot be read.
    #
    # @api public
    # @param keys [Array<Symbol>, nil] the names the pattern asks for, or nil for all of them
    # @return [Hash{Symbol => Object}] the requested attributes, without the ones that cannot be read
    # @example Match a vehicle by its state
    #   case Tesla.vehicle("5YJSA11111111111")
    #   in {state: "online", display_name:} then display_name
    #   end
    def deconstruct_keys(keys)
      names = self.class.attribute_names
      names &= keys unless keys.nil?
      requested = {} #: Hash[Symbol, untyped]
      names.each do |name|
        requested[name] = public_send(name)
      rescue InvalidResponse
        # The attribute cannot be read, so the pattern is answered without it
      end
      requested
    end

    # Compare with another resource
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Boolean] true if the other object is the same kind of resource with the same identity
    # @example Compare two vehicles
    #   Tesla.vehicle("5YJSA11111111111") == Tesla.vehicle("5YJSA11111111111") # => true
    def ==(other)
      other.instance_of?(self.class) && identity == other.identity
    end

    # Compare with another resource for use as a hash key
    #
    # Unlike {#==}, identity values are compared with `eql?`, so this agrees with {#hash}.
    #
    # @api public
    # @param other [Object] the object to compare with
    # @return [Boolean] true if the other object is the same kind of resource with an eql? identity
    # @example Compare two vehicles strictly
    #   Tesla.vehicle("5YJSA11111111111").eql?(Tesla.vehicle("5YJSA11111111111")) # => true
    def eql?(other)
      other.instance_of?(self.class) && identity.eql?(other.identity)
    end

    # Summarize the resource for the console
    #
    # Only the readers declared with {.inspect_with} are shown, so the output stays short and never includes secrets.
    #
    # @api public
    # @return [String] the summary
    # @example Inspect a vehicle
    #   vehicle.inspect # => #<Tesla::Vehicle vin="5YJSA11111111111" display_name="Nikola 2.0" state="online">
    def inspect
      fields = inspect_values.map { |reader, value| " #{reader}=#{value.inspect}" }
      "#<#{self.class}#{fields.join}>"
    end

    # Summarize the resource as a String
    #
    # The summary {#inspect} answers with, so that a resource written into a message or a log reads as the one the
    # console shows rather than as the address the object sits at.
    #
    # @api public
    # @return [String] the summary
    # @example Write a vehicle into a message
    #   "woke #{vehicle}" # => 'woke #<Tesla::Vehicle vin="5YJSA11111111111" display_name="Nikola 2.0" state="online">'
    def to_s = inspect

    # Generate a hash code for the resource
    #
    # @api public
    # @return [Integer] the hash code
    # @example Use resources as hash keys
    #   {vehicle => true}
    def hash
      [self.class, identity].hash
    end

    protected

    # The values that identify the resource
    #
    # A resource answers with these to the resource it is compared with, rather than to a caller, which reads the
    # readers {.identified_by} names or the attributes themselves: the values are what the comparison is made of,
    # and are an Array of readers for one resource and the whole of the attributes for another.
    #
    # @api private
    # @return [Array<Object>, Hash{String => Object}] the identifying values, or all attributes when no identity is
    #   declared
    # @example Compare two vehicles by the VIN that identifies them
    #   Tesla.vehicle("5YJSA11111111111") == Tesla.vehicle("5YJSA11111111111") # => true
    def identity
      readers = self.class.identity_readers
      readers.empty? ? attributes : readers.map { |reader| public_send(reader) }
    end

    private

    # The readers {#inspect} shows, with their values
    #
    # These are the readers {.inspect_with} declares, which a resource that shows more when it has it adds to.
    #
    # @api private
    # @return [Hash{Symbol => Object}] the value of each reader shown, in the order they are shown
    def inspect_values = self.class.inspect_readers.to_h { |reader| [reader, public_send(reader)] }

    # The value of the first of the given keys the response contains
    # @api private
    # @param keys [Array<String>] the attribute keys, most preferred first
    # @return [Object, nil] the value, or nil when the response contains none of the keys
    def value_of(keys)
      keys.each { |key| return self[key] if attributes.key?(key) }
      nil
    end

    # Read a timestamp attribute as a Time in UTC
    #
    # The attribute is the milliseconds since the Unix epoch, which are read as a Rational number of seconds so that
    # none of them are lost to a Float.
    #
    # @api private
    # @param value [Object] the attribute value
    # @return [Time] the time
    # @raise [InvalidResponse] if the value is not a timestamp
    def parse_time(value)
      Time.at(Rational(value, 1000), in: "UTC")
    rescue ArgumentError, TypeError
      raise InvalidResponse.new(body: value.to_s, message: "#{value.inspect} is not a timestamp")
    end
  end
end
