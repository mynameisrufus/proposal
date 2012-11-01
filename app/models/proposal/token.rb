module Proposal
  class Token < ActiveRecord::Base

    belongs_to :resource,
      polymorphic: true

    attr_accessible :email,
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

    serialize :arguments

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
      token = where(constraints).first
      token.nil? ? new(options) : token
    end

    def args= args_array
      if args_array.first.is_a?(Hash) && args_array.size == 1
        self.arguments = args_array.first
      else
        self.arguments = args_array
      end
      self
    end

    def args
      self.arguments
    end

    def action
      case
        when persisted?
          :remind
        when recipient.nil?
          :invite
        else
          :notify
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

    def self.pending
      where('accepted_at IS NULL')
    end

    def self.accepted
      where('accepted_at IS NOT NULL')
    end

    def self.expired
      where('expires_at < ?', Time.now)
    end

    def self.reminded
      where('reminded_at IS NOT NULL')
    end

    def expires= expires_proc
      unless expires_proc.is_a? Proc
        raise ArgumentError, 'expires must be a proc'
      end
      self.expires_at = expires_proc.call
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
  end
end
