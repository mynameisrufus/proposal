# Proposal

Simple unobtrusive token invitation engine for use with any authentication
framework. Makes no fuss and no redundant records.

## Installation

Add this line to your application's Gemfile:

    gem 'proposal'

And then execute:

    $ bundle

Then run migrations to add the `proposal_tokens` table:

    $ rake proposal:install:migrations
    $ rake db:migrate

## Proposable Models

```ruby
class User < ActiveRecord::Base
  can_propose
end
```

## Making Proposals

When your token is return you need to check what to do next, for example if the
user does not exist they then need to get sent an invitation.

```ruby
@proposal = User.propose('user@example.com').to(@project)
@proposal.action #=> :invite
if @proposal.save!
  @url = acceptance_url(token: @proposal)
  # send out invitation
end
```

Conversely if they are already a user then they need to get an email inviting
them or an email notifying that they have been added to something.

```ruby
@proposal = User.propose('user@example.com').to(@project)
@proposal.action #=> :notify
if @proposal.save!
  @project.users << proposal.user
  # send out notification
end
```

Finally if the user already has an outstanding invitation they may just need a
reminder.

```ruby
@proposal = User.propose('user@example.com').to(@project)
@proposal.action #=> :remind
if @proposal.reminded!
  # send out reminder
end
```

All actions have convenience methods for example:

```ruby
@proposal.notify?
```

## Proposal Resources

In some situations you might want to send out many invitations to different
things.

```ruby
@proposal = User.propose('user@example.com').to(@project)
@proposal.resource # => Project
```

## Accepting Proposals

```ruby
@proposal = User.proposals.find_by_token 'pVBJYdr3zH4B9yXWwsmy'

@proposal.accepted? #= false
@proposal.expired? #=> false
@proposal.acceptable? #=> true

if @proposal.accept!
  @project.users << @proposal.user
end
```

## Proposal Arguments

You may need to store custom arguments such as the role a user may get upon
acceptance. It also has a validator that takes an array, hash or proc.

```ruby
class User < ActiveRecord::Base
  can_propose expects: :role
end

@proposal = User.propose('user@example.com').with(role: 'admin')
@proposal.arguments # => :role => 'admin'
```

## Token Expiry

The default tokens expire in one year, however you can change this.

```ruby
class User < ActiveRecord::Base
  can_propose expires: -> { Time.now + 10.days }
end

@proposal = User.propose('user@example.com', expires_at: Time.now - 1.day)
@proposal.expired? # => true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
