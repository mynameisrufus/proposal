module Proposal
  class Token < ActiveRecord::Base

    belongs_to :resource, polymorphic: true

    serialize :arguments

    attr_accessible :email,
      :arguments,
      :proposable,
      :proposable_type,
      :expires,
      :expects,
      :resource,
      :args

    attr_writer :expects

    validates_presence_of :email,
      :token,
      :proposable,
      :proposable_type,
      :expires_at

    validates_with ::Proposal::ArgumentsValidator, if: -> {
      expects.present?
    }

    validates_with ::Proposal::EmailValidator

    validates :email,
      uniqueness: {
        scope: [
          :proposable_type,
          :resource_type,
          :resource_id
        ],
        message: "already has an outstanding proposal"
      }

    before_validation on: :create do
      self.token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
    end

    before_validation on: :create do
      self.expires_at = Time.now + 1.year unless self.expires_at
    end

    validate :validate_expiry, :validate_accepted

    def validate_expiry
      errors.add :token, "has expired" if expired?
    end

    def validate_accepted
      errors.add :token, "has been accepted" if accepted?
    end

    scope :pending, where('accepted_at IS NULL')

    scope :accepted, where('accepted_at IS NOT NULL')

    scope :expired, where('expires_at < ?', Time.now)

    scope :reminded, where('reminded_at IS NOT NULL')

    def expects
      @expects || proposable.proposal_options[:expects]
    end

    def proposable
      @proposable ||= self.proposable_type.constantize
    end

    def proposable= type
      self.proposable_type = type.to_s
    end

    def recipient!
      raise Proposal::RecordNotFound if recipient.nil?
      recipient
    end

    def recipient
      @recipient ||= self.proposable.where(email: self.email).first
    end

    def self.find_or_new options
      constraints = options.slice :email, :proposable_type
      resource = options[:resource]
      if !resource.nil? && resource.respond_to?(:id)
        constraints.merge! resource_type: resource.class.to_s,
          resource_id: resource.id
      end
      token = pending.where(constraints).first
      token.nil? ? new(options) : token
    end

    def action
      acceptable? ? acceptable_action : nil
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

    def accepted?
      !accepted_at.nil?
    end

    def expired?
      Time.now >= self.expires_at
    end

    # Calls proc to set the +expires_at+ attribute.
    def expires= expires_proc
      unless expires_proc.is_a? Proc
        raise ArgumentError, 'expires must be a proc'
      end
      self.expires_at = expires_proc.call
    end

    # Returns a +true+ if the proposal has not expired and the proposal has not
    # already been accepted. Also calls +valid?+ to set +ActiveModel::Validator+
    # validators for +expires_at+ and +accepted_at+.
    def acceptable?
      valid?
      !expired? && !accepted?
    end

    # Sets +Time.now+ for the +reminded_at+ field in the database if the
    # proposal action is +:remind+. This method can be called repeatedly.
    def reminded
      touch :reminded_at if remind?
      remind?
    end

    # Equivalent to +reminded+ except it will raise a +Proposal::RemindError+ if
    # the proposal action is not +:remind+
    def reminded!
      raise Proposal::RemindError, 'proposal action is not remind' unless remind?
      reminded
    end

    # Sets +Time.now+ for the +accepted_at+ field in the database if the
    # proposal is acceptable.
    def accept
      if acceptable?
        touch :accepted_at
        true
      else
        false
      end
    end

    # Equivalent +accept+ except it will raise a +Proposal::ExpiredError+ if the
    # proposal has expired or a +Proposal::AccepetedError+ if the proposal has
    # already been accepted.
    def accept!
      raise Proposal::ExpiredError, 'token has expired' if expired?
      raise Proposal::AccepetedError, 'token has been used' if accepted?
      touch :accepted_at
      true
    end

    def to_s
      token
    end

    protected

    # Returns a symbol of what action the proposal needs. This method should
    # only be called if the the proposable is acceptable.
    def acceptable_action
      case
      when persisted? then :remind
      when recipient.nil? then :invite
      else :notify
      end
    end
  end
end
