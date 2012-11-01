module Proposal
  class ArgumentsValidator < ActiveModel::Validator

    def validate_expected record, sym
      unless record.arguments[sym].present?
        record.errors.add :arguments, "is missing #{sym}"
      end
    end

    def validate record
      if record.expects.is_a? Proc
        unless record.expects.call(record.arguments)
          record.errors.add :arguments, "is invalid"
        end
      elsif record.arguments.is_a? Hash
        case record.expects
        when Symbol
          validate_expected record, record.expects
        when Array
          record.expects.each { |sym| validate_expected record, sym }
        end
      else
        record.errors.add :arguments, "must be a hash"
        case record.expects
        when Symbol
          record.errors.add :arguments, "is missing #{record.expects}"
        when Array
          record.expects.each do |sym|
            record.errors.add :arguments, "is missing #{sym}"
          end
        end
      end
    end

  end
end
