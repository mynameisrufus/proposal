require 'test_helper'

class ProposalTest < ActiveSupport::TestCase
  def email
    "user@example.com"
  end

  test "truth" do
    assert_kind_of Module, Proposal
  end

  test "user should have proposal" do
    assert_equal User.propose.class, Proposal::Adapter
    assert_equal User.propose.to(email).class, Proposal::Token
  end

  test "should respond to the recipient" do
    user = User.create email: email
    proposal = User.propose.to email
    assert_equal user, proposal.recipient
  end

  test "should add errors when not acceptable accepted safe" do
    errors = {:token=>["has been accepted"]}
    proposal = User.propose.to email
    proposal.save
    assert_equal true, proposal.accept
    assert_equal false, proposal.accept
    assert_equal errors, proposal.errors.messages
  end

  test "should add errors when not acceptable accepted" do
    errors = {:token=>["has been accepted"]}
    proposal = User.propose.to email
    proposal.save
    proposal.accept!
    assert_equal false, proposal.acceptable?
    assert_equal errors, proposal.errors.messages
  end

  test "should add errors when not acceptable expired" do
    errors = {:token=>["has expired"]}
    proposal = User.propose.to email
    proposal.save
    proposal.expires = -> { Time.now - 1.day }
    assert_equal false, proposal.acceptable?
    assert_equal errors, proposal.errors.messages
  end

  test "should respond to the resource" do
    project = Project.create!
    user = User.create email: email
    proposal = User.propose(project).to email
    assert_equal project, proposal.resource
  end

  test "should create valid proposal token" do
    proposal = User.propose.to email
    proposal.save

    assert_equal proposal.token.class, String
  end

  test "should return all proposals for type" do
    proposal = User.propose.to email
    proposal.save

    assert_equal User.proposals, [proposal]
  end

  test "should accept a resource" do
    project_one = Project.create!

    context_one = User.propose(project_one).to(email)
    assert_equal true, context_one.save

    project_two = Project.create!

    context_two = User.propose(project_two).to(email)
    assert_equal true, context_two.save

    context_three = User.propose(project_two).to(email)
    assert_equal context_two, context_three
  end

  test "should return the resource" do
    project = Project.create!
    proposal = User.propose(project).to(email)
    assert_equal proposal.resource, project
  end

  test "should return all arguments" do
    arguments = ['admin', 1]
    proposal = User.propose.with(arguments).to('user@example.com')
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should return hash when arguments is hash" do
    arguments = { role: 'admin' }
    proposal = User.propose.with(arguments).to(email)

    assert_equal true, proposal.save

    retrieved = User.proposals.find_by_token proposal.token
    assert_equal arguments, retrieved.arguments
  end

  test "should validate arguments with symbol" do
    error_messages = ["must be a hash", "is missing role"]
    errors = { arguments: error_messages }
    proposal = User.propose.to email, expects: :role

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbol and args" do
    error_messages = ["is missing role"]
    errors = { arguments: error_messages }
    proposal = User.propose.to email
    proposal.expects = :role

    proposal.arguments = { extra: 'foo' }

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with symbols" do
    error_messages = ["must be a hash", "is missing role", "is missing count"]
    errors = { arguments: error_messages }
    proposal = User.propose.to email, expects: [:role, :count]

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should validate arguments with a proc" do
    error_messages = ["is invalid"]
    errors = { arguments: error_messages }
    proposal = User.propose.to email, expects: -> arguments {
      !arguments.nil? && !arguments.empty?
    }

    assert_equal false, proposal.valid?
    assert_equal errors, proposal.errors.messages
  end

  test "should return proposal instance" do
    user = User.create email: email
    proposal = User.propose.to email
    assert_equal user, proposal.recipient
    assert_equal true, proposal.notify?
  end

  test "should not return proposal instance" do
    proposal = User.propose.to email
    assert_equal nil, proposal.recipient
    assert_raises(Proposal::RecordNotFound) { proposal.recipient! }
  end

  test "should not return proposal action notify" do
    user = User.create email: email
    proposal = User.propose.to email
    assert_equal :notify, proposal.action
    assert_equal true, proposal.notify?
  end

  test "should not return proposal action invite" do
    proposal = User.propose.to email
    assert_equal :invite, proposal.action
    assert_equal true, proposal.invite?
  end

  test "should have action remind for invite (new user)" do
    existing = User.propose.to email
    existing.save!

    proposal = User.propose.to email

    assert_equal true, proposal.remind?
    assert_equal true, proposal.invite_remind?
    assert_equal false, proposal.notify_remind?
    assert_equal :invite_remind, proposal.action
  end

  test "should have action remind for notify (existing user)" do
    user = User.create email: email
    existing = User.propose.to email
    existing.save!

    proposal = User.propose.to email

    assert_equal true, proposal.remind?
    assert_equal true, proposal.notify_remind?
    assert_equal false, proposal.invite_remind?
    assert_equal :notify_remind, proposal.action
  end

  test "should not return no action if accepted" do
    proposal = User.propose.to email
    proposal.save!
    proposal.accept!

    assert_equal nil, proposal.action
  end

  test "should raise error if remind is not true" do
    proposal = User.propose.to email
    assert_raises(Proposal::RemindError) { proposal.reminded! }
  end

  test "should set reminded safe" do
    user = User.create email: email
    existing = User.propose.to email
    existing.save!

    proposal = User.propose.to email
    assert_equal true, proposal.reminded
    assert_equal true, proposal.reminded?
  end

  test "should set reminded bang" do
    user = User.create email: email
    existing = User.propose.to email
    existing.save!

    proposal = User.propose.to email
    assert_equal true, proposal.reminded!
    assert_equal true, proposal.reminded?
  end

  test "should find and accept proposal" do
    email = "user@example.com"
    user = User.create email: email
    proposal = User.propose.to email
    proposal.save

    retrieved = User.proposals.find_by_token proposal.token

    assert_equal retrieved, proposal

    retrieved.accept!

    assert_equal true, retrieved.accepted?
  end

  test "should return token from to_s method" do
    proposal = User.propose.to email
    proposal.save
    assert_equal proposal.token, proposal.to_s
  end

  test "should create a new token if accepted token exists" do
    project = Project.create!
    user = User.create email: email
    existing = User.propose(project).to email
    existing.save!
    existing.accept!

    proposal = User.propose(project).to email
    proposal.save!
    assert_equal false, existing.acceptable?
    assert_equal true, proposal.acceptable?
  end

  test "should not create a new token if token exists" do
    token_one = Proposal::Token.new email: email,
      proposable_type: User.to_s

    token_two = Proposal::Token.new email: email,
      proposable_type: User.to_s

    errors = { email: ["already has an outstanding proposal"] }

    assert_equal true, token_one.save
    assert_equal false, token_two.save
    assert_equal errors, token_two.errors.messages
  end

  test "should return proposals for resource instance" do
    user = User.create email: email
    project = Project.create!
    proposal = User.propose(project).to(email)
    proposal.save

    assert_equal [proposal], project.proposals 
  end

  test "should return proposals for proposer instance" do
    user = User.create email: email
    proposal = user.propose.to email
    proposal.save

    assert_equal [proposal], user.proposals
  end
end
