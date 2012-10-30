module Proposal

  class ExpiredError < StandardError; end

  class AccepetedError < StandardError; end

  class RemindError < StandardError; end

  class RecordNotFound < StandardError; end

  class Engine < ::Rails::Engine
    isolate_namespace Proposal

    module CanPropose
      module ClassMethods
        def can_propose options = {}
          @proposal_options = options.merge proposable_type: self.to_s
        end

        def propose email, *args
          context = args.empty? ? nil : args.join(':')
          options = @proposal_options.merge email: email, context: context
          ProposalToken.find_or_return options
        end

        def proposals
          ProposalToken.where(proposable_type: self.to_s)
        end
      end

      def self.included(base)
        base.send :extend, ClassMethods
      end
    end

    initializer "proposal.configure" do |app|
      ActiveSupport.on_load :active_record do
        include CanPropose
      end
    end
  end
end
