require "gamefic/node"
require "gamefic/describable"
require 'gamefic/messaging'

module Gamefic

  class Entity
    include Node
    include Describable
    include Messaging
    include Grammar::WordAdapter

    def initialize(args = {})
      self.class.default_attributes.merge(args).each { |key, value|
        send "#{key}=", value
      }
      post_initialize
      yield self if block_given?
    end

    def uid
      if @uid == nil
        @uid = self.object_id.to_s
      end
      @uid
    end

    def default_attributes
      {}
    end

    def post_initialize
      # raise NotImplementedError, "#{self.class} must implement post_initialize"
    end

    # Execute the entity's on_update blocks.
    # This method is typically called by the Engine that manages game execution.
    # The base method does nothing. Subclasses can override it.
    #
    def update
    end
    
    # Set the Entity's parent.
    #
    # @param node [Entity] The new parent.
    def parent=(node)
      if node != nil and node.kind_of?(Entity) == false
        raise "Entity's parent must be an Entity"
      end
      super
    end

    # @return [Hash]
    def session
      @session ||= {}
    end

    # Get an extended property.
    #
    # @param key [Symbol] The property's name.
    def [](key)
      session[key]
    end
    
    # Set an extended property.
    #
    # @param key [Symbol] The property's name.
    # @param value The value to set.
    def []=(key, value)
      session[key] = value
    end

    class << self
      def set_default attrs = {}
        default_attributes.merge! attrs
      end

      def default_attributes
        @default_attributes ||= {}
      end

      def inherited subclass
        subclass.set_default default_attributes
      end
    end
  end

end
