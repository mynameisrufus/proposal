class ProposalToken < ActiveRecord::Base

  # Validator for serialized arguments
  #
  # Validation only applies if the arguments are a hash and the expects option
  # has been specified on the model.
  #
  # Example:
  #
  #   class User < ActiveRecord::Base
  #     can_propose expects: [:role, :count]
  #   end
  #
  #   user = User.proposal.make "user@example.com", role: 'admin'
  #   user.valid? # => false
  #
  # It is also possible to use a Proc:
  #
  #   class User < ActiveRecord::Base
  #     can_propose expects: arguments -> { arguments.first.is_a?(Integer) }
  #   end
  #
  #   user = User.proposal.make "user@example.com", 10, 'foo'
  #   user.valid? # => true
  #
  class ArgumentsValidator < ActiveModel::Validator
    def validate_expected record, sym
      record.errors.add :arguments, "is missing #{sym}" unless
        record.arguments[sym].present?
    end

    def validate record
      if record.expects.is_a? Proc
        record.errors.add :arguments, "is invalid" unless
          record.expects.call(record.arguments)
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

  class EmailValidator < ActiveModel::Validator
    def validate record
      record.errors.add :email, "is not valid" unless
        record.email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    end
  end

  attr_accessor :expects

  attr_accessible :email, :proposable, :arguments, :expires, :expects

  validates_presence_of :email, :token, :proposable_type, :expires_at

  validates_with ArgumentsValidator, if: -> { expects.present? }

  validates_with EmailValidator

  serialize :arguments

  validates :email, uniqueness: {
    scope: :proposable_type,
    message: "already has an outstanding invitation"
  }

  before_validation on: :create do
    self.token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
  end

  before_validation on: :create do
    self.expires_at = Time.now + 1.year unless self.expires_at
  end

  def proposable= type
    self.proposable_type = type.to_s
  end

  def proposable
    @proposable ||= constantize_proposable
  end

  def constantize_proposable
    self.proposable_type.nil? ? nil : self.proposable_type.constantize
  end

  def instance
    @instance ||= self.proposable.find_by_email self.email
  end

  def make email, *args
    self.email = email
    if args.first.is_a?(Hash) && args.size == 1
      self.arguments = args.first
    else
      self.arguments = args
    end
    self
  end

  def action
    instance.nil? ? :invite : :notify
  end

  def notify?
    action == :notify
  end

  def invite?
    action == :invite
  end

  def accept
    touch :accepted_at
  end

  def accepted?
    !accepted_at.nil?
  end

  def expired?
    Time.now >= self.expires_at
  end

  def expires= time
    self.expires_at = time
  end

  def accept
    touch :accepted_at unless expired?
    !expired?
  end

  def accept!
    raise Proposal::ExpiredError, 'token has expired' if expired?
    touch :accepted_at
    true
  end

  def method_missing(meth, *args, &block)
    if meth.to_s == proposable_type.to_s.downcase
      proposable
    else
      super
    end
  end

end
