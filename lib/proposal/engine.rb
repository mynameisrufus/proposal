module Proposal

  class ExpiredError < StandardError; end

  class AccepetedError < StandardError; end

  class RemindError < StandardError; end

  class RecordNotFound < StandardError; end

  # Wrapper object for the ORM. In this case it only supports ActiveRecord. In
  # theory you could write an Adapter for each different ORM then use the rails
  # initializer to add.
  class Adapter
    def initialize options
      @options = options
    end

    def with *args
      @options.merge! args: args
      self
    end

    alias :with_args :with

    # Method to return in instantiate the proposal object using an email
    # address.
    def to email, options = {}
      Token.find_or_new @options.merge(options).merge email: email
    end

    def invite options
      Token.find_or_new @options.merge(options)
    end

    # Delegates to ORM object and returns all proposal objects for given type.
    def self.where options
      Token.where options
    end
  end

  module CanPropose

    # Module for adding in class methods to object. For example:
    #
    # ==== Example
    #
    #    User < ActiveRecord::Base
    #      can_propose
    #    end
    #
    module ClassMethods

      # Class method for configuring default behaviour in ORM object.
      #
      # ==== Options
      #
      # * +:expires+ - A proc that returns a +DateTime+"
      # * +:expects+ - Symbol or array of expected keys in arguments"
      def can_propose options = {}
        @proposal_options = options.merge proposable_type: self.to_s
      end

      # Getter for +@proposal_options+
      def proposal_options
        @proposal_options
      end

      # Class method for returning a new instance of +Adapter+
      #
      # Optional +resource+ argument that the ORM stores a reference to. This
      # enables the email address to have multiple proposals for different
      # unique resources.
      def propose resource = nil
        Adapter.new @proposal_options.merge resource: resource
      end

      # Delegate method to return all the proposals for the ORM object.
      def proposals
        Adapter.where proposable_type: self.to_s
      end
    end

    module InstanceMethods
      def proposals
        Adapter.where resource_type: self.class.to_s, resource_id: self.id
      end
    end

    def self.included base
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
  end

  class Engine < ::Rails::Engine
    isolate_namespace Proposal

    initializer "proposal.configure" do |app|
      ActiveSupport.on_load :active_record do
        include CanPropose
      end
    end
  end
end
