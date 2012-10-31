class User < ActiveRecord::Base
  attr_accessible :email

  can_propose expires: -> { Time.now + 1.day }
end
