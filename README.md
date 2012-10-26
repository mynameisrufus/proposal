# Proposal

Simple unobtrusive token invitation engine for use with any authentication
framework. Makes no fuss and no redundant records.

## Installation

Add this line to your application's Gemfile:

    gem 'proposal'

And then execute:

    $ bundle

Then run migrations to add the `proposal_tokens` table:

    $ gem install proposal

    $ rake proposal:install:migrations
    $ rake db:migrate

## Usage

    class User < ActiveRecord::Base
      can_propose expires: Time.now + 10.days
    end

    proposal = User.proposal.make 'user@example.com'

    # If user needs an invite
    proposal.action # => :invite

    # If user needs to be notified
    proposal.action # => :notify

    # If proposal action is notify then you can choose to send out a seperate
    # kind of invitation or just add them to what they are being invited to and
    # then just notify them.
    if proposal.notify?
      Project.users << proposal.user
    end

    if proposal.save
      if proposal.notify?
        UserMailer.notify_email @proposal
      else
        UserMailer.invitation_email @proposal
      end
    end

    proposal = User.proposal.find 'pVBJYdr3zH4B9yXWwsmy'

    proposal.accepted?
    proposal.expired?
    proposal.accept
    proposal.valid?
    proposal.errors

    proposal = User.proposal.find! 'pVBJYdr3zH4B9yXWwsmy'
    => Proposal::ExpiredError # token expired
    => ActiveRecord::RecordNotFound # could not find proposal token

    proposal.accept!
    => Proposal::AccepetedError # token allready accepted

See the dummy app in the test dir on how you might use it in a controller.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
