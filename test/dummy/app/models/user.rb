class User < ActiveRecord::Base

  can_propose expires: -> { Time.now + 1.day }

end
