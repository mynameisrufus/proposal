require 'test_helper'

class ProposalTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Proposal
  end

  test "user should have proposal" do
    assert_equal User.proposal.class, ProposalToken
  end

  test "should respond to the proposable" do
    proposal = User.proposal.make 'user@example.com'
    assert_equal User, proposal.user
  end

  test "should create valid proposal token" do
    proposal = User.proposal.make 'user@example.com'
    proposal.save

    assert_equal proposal.token.class, String
  end

  test "should return all proposals for type" do
    proposal = User.proposal.make 'user@example.com'
    proposal.save

    assert_equal User.proposals, [proposal]
  end

  test "should return all arguments" do
    arguments = ['admin', 1]
    proposal = User.proposal.make 'user@example.com', *arguments
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should return hash when arguments is hash" do
    arguments = { role: 'admin' }
    proposal = User.proposal.make 'user@example.com', arguments
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should validate arguments with symbol" do
    error_messages = ["must be a hash", "is missing role"]
    errors = { arguments: error_messages }
    proposal = User.proposal
    proposal.expects = :role

    proposal.make "user@example.com"

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbol and args" do
    error_messages = ["is missing role"]
    errors = { arguments: error_messages }
    proposal = User.proposal
    proposal.expects = :role

    proposal.make "user@example.com", extra: 'foo'

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbols" do
    error_messages = ["must be a hash", "is missing role", "is missing count"]
    errors = { arguments: error_messages }
    proposal = User.proposal
    proposal.expects = [:role, :count]

    proposal.make "user@example.com"

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with a proc" do
    error_messages = ["is invalid"]
    errors = { arguments: error_messages }
    proposal = User.proposal
    proposal.expects = -> arguments do
      !arguments.empty?
    end

    proposal.make "user@example.com"

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should return proposal instance" do
    email = "user@example.com"
    user = User.create email: email
    proposal = User.proposal.make email
    assert_equal user, proposal.instance
    assert_equal true, proposal.notify?
  end

  test "should not return proposal instance" do
    proposal = User.proposal.make "user@example.com"
    assert_equal nil, proposal.instance
    assert_equal true, proposal.invite?
  end

  test "should not return proposal action notify" do
    email = "user@example.com"
    user = User.create email: email
    proposal = User.proposal.make email
    assert_equal :notify, proposal.action
    assert_equal true, proposal.notify?
  end

  test "should not return proposal action invite" do
    proposal = User.proposal.make "user@example.com"
    assert_equal :invite, proposal.action
    assert_equal true, proposal.invite?
  end

  test "should find and accept proposal" do
    email = "user@example.com"
    user = User.create email: email
    proposal = User.proposal.make email
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token

    assert_equal retrieved, proposal

    retrieved.accept!

    assert_equal true, retrieved.accepted?
  end
end
