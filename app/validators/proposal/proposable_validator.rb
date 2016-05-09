module Proposal
  class ProposableValidator < ActiveModel::Validator

    def validate record
      unless record.proposable.is_a?(Class)
        record.errors.add :proposable, "is not a class"
      end
    end

  end
end
