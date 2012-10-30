class ProposalToken < ActiveRecord::Base

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

  attr_accessible :email, :context, :proposable, :proposable_type, :expires,
                  :expect

  validates_presence_of :email, :token, :proposable, :proposable_type,
                        :expires_at

  validates_with ArgumentsValidator, if: -> { expects.present? }

  validates_with EmailValidator

  serialize :arguments

  validates :email, uniqueness: {
    scope: [:proposable_type, :context],
    message: "already has an outstanding proposal"
  }

  def self.context *args
    where context: args.join(':')
  end

  before_validation on: :create do
    self.token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
  end

  before_validation on: :create do
    self.expires_at = Time.now + 1.year unless self.expires_at
  end

  def proposable
    @proposable ||= self.proposable_type.constantize
  end

  def proposable= type
    self.proposable_type = type.to_s
  end

  def instance!
    raise Proposal::RecordNotFound if instance.nil?
    instance
  end

  def instance
    @instance ||= self.proposable.where(email: self.email).first
  end

  def self.find_or_return options
    constraints = options.slice :email, :context, :proposable_type
    token = where(constraints).first
    token.nil? ? new(options) : token
  end

  def with *args
    if args.first.is_a?(Hash) && args.size == 1
      self.arguments = args.first
    else
      self.arguments = args
    end
    self
  end

  alias :with_args :with

  def action
    case
      when persisted? then :remind
      when instance.nil? then :invite
      else :notify
    end
  end

  def notify?
    action == :notify
  end

  def invite?
    action == :invite
  end

  def remind?
    action == :remind
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

  def acceptable?
    !expired? && !accepted?
  end

  def reminded
    touch :reminded_at if remind?
    remind?
  end

  def reminded!
    raise Proposal::RemindError, 'proposal has not been made' unless remind?
    reminded
  end

  def accept
    touch :accepted_at if acceptable?
    acceptable?
  end

  def accept!
    raise Proposal::ExpiredError, 'token has expired' if expired?
    raise Proposal::AccepetedError, 'token has been used' if accepted?
    touch :accepted_at
    true
  end

  def to_s
    token
  end

  def method_missing(meth, *args, &block)
    if meth.to_s == self.proposable_type.downcase
      instance!
    else
      super
    end
  end

end
