require 'test_helper'

class ProposalTest < ActiveSupport::TestCase
  def email
    "user@example.com"
  end

  test "truth" do
    assert_kind_of Module, Proposal
  end

  test "user should have proposal" do
    assert_equal User.propose(email).class, ProposalToken
  end

  test "should respond to the proposable" do
    user = User.create email: email
    proposal = User.propose email
    assert_equal user, proposal.user
  end

  test "should create valid proposal token" do
    proposal = User.propose email
    proposal.save

    assert_equal proposal.token.class, String
  end

  test "should return all proposals for type" do
    proposal = User.propose email
    proposal.save

    assert_equal User.proposals, [proposal]
  end

  test "should accept a context" do
    context_one = User.propose email, :one
    assert_equal true, context_one.save

    context_two = User.propose email, :two
    assert_equal true, context_two.save

    context_three = User.propose email, :two
    assert_equal context_two, context_three
  end

  test "should return all arguments" do
    arguments = ['admin', 1]
    proposal = User.propose('user@example.com').with(*arguments)
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should return hash when arguments is hash" do
    arguments = { role: 'admin' }
    proposal = User.propose(email).with(arguments)

    assert_equal true, proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should validate arguments with symbol" do
    error_messages = ["must be a hash", "is missing role"]
    errors = { arguments: error_messages }
    proposal = User.propose email
    proposal.expects = :role

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbol and args" do
    error_messages = ["is missing role"]
    errors = { arguments: error_messages }
    proposal = User.propose email
    proposal.expects = :role

    proposal.with extra: 'foo'

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbols" do
    error_messages = ["must be a hash", "is missing role", "is missing count"]
    errors = { arguments: error_messages }
    proposal = User.propose email
    proposal.expects = [:role, :count]

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with a proc" do
    error_messages = ["is invalid"]
    errors = { arguments: error_messages }
    proposal = User.propose email
    proposal.expects = -> arguments do
      !arguments.nil? && !arguments.empty?
    end

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should return proposal instance" do
    user = User.create email: email
    proposal = User.propose email
    assert_equal user, proposal.instance
    assert_equal true, proposal.notify?
  end

  test "should not return proposal instance" do
    proposal = User.propose email
    assert_raises(Proposal::RecordNotFound) { proposal.instance! }
    assert_raises(Proposal::RecordNotFound) { proposal.user }
  end

  test "should not return proposal action notify" do
    user = User.create email: email
    proposal = User.propose email
    assert_equal :notify, proposal.action
    assert_equal true, proposal.notify?
  end

  test "should not return proposal action invite" do
    proposal = User.propose email
    assert_equal :invite, proposal.action
    assert_equal true, proposal.invite?
  end

  test "should not return proposal action remind" do
    user = User.create email: email
    existing = User.propose(email)
    existing.save!
    existing.accept!

    proposal = User.propose email
    assert_equal :remind, proposal.action
    assert_equal true, proposal.remind?
  end

  test "should set reminded" do
    user = User.create email: email
    existing = User.propose(email)
    existing.save!
    existing.accept!

    proposal = User.propose email
    assert_equal true, proposal.reminded!
  end

  test "should find and accept proposal" do
    email = "user@example.com"
    user = User.create email: email
    proposal = User.propose email
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token

    assert_equal retrieved, proposal

    retrieved.accept!

    assert_equal true, retrieved.accepted?
  end

  test "should return token from to_s method" do
    proposal = User.propose(email)
    proposal.save
    assert_equal proposal.token, proposal.to_s
  end
end
