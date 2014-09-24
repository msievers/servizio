# Servizio

Servizio is a gem to support you writing service objects.

## Installation

Add this line to your application's Gemfile:

    gem 'servizio'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install servizio

## Usage

```ruby
require "servizio"

class ChangePassword < Servizio::Service
  attr_accessor :current_password
  attr_accessor :new_password
  attr_accessor :new_password_confirmation
  attr_accessor :user

  validates_presence_of :current_password
  validates_presence_of :new_password
  validates_presence_of :new_password_confirmation
  validates_confirmation_of :new_password
  validates_presence_of :user
  
  def call
    Some::External::WebService.change_user_password(user.id, current_password, new_password)
  end
end

operation = ChangePassword.new(
  user: current_user,
  current_password: "test",
  new_password: "123",
  new_password_confirmation: "123"
)

operation.on_invalid -> (operation) do
  render change_password_user_path
end

operation.on_success -> (operation) do
  flash[:success] = "Password changed!"
  redirect_to :user_path
end

operation.call
```

## Additional readings
* https://netguru.co/blog/service-objects-in-rails-will-help
* http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html

## Contributing

1. Fork it ( https://github.com/[my-github-username]/servizio/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
