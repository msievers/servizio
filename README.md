# Servizio

Servizio is a gem to support you creating service objects. It was created after I read a blog post about [service objects](http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html) from [Philippe Creux](https://twitter.com/pcreux). Realy great post, check it out.

I liked the ideas presented there, so I began to use them. Quickly I realised, that combining the basic concepts presented in this post with something like ```ActiveModel``` would be awesome. So there was ```Servizio```.  

## The basic ideas

For those who haven't read the original [post](http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html), let's sum up it's basic thoughts.

### A service object *does one thing*

A service object should hold the business logic to perform one action, e.g. to change a users password. It should start with a verb (but your mileage may vary). When used with rails, the should be homed in ```app/services```. In order to keep things organzied, subdirectories/modules should be used, e.g. ```app/services/user/change_password``` which corresponds to ```User::ChangePassword```.

Generally subdirectories/modules holding services should be named with the singular noun, representing the object they manipulate, e.g. ```app/services/user/...``` not ```users```, resulting in ```User::ChangePassword``` not ```Users::...``` That way, things are consistent with the rails naming convention regarding models.

That does not mean that there have to be a corresponding model if you create a service subdirectory. It's only a convention. So you are free to create something like ```app/services/statistic/create.rb```, allthough there is no ```Statistic``` model. It should be all about business logic. If there is a corresponding model, fine. If not, never mind.

A service object should respond to the ```call``` method. It's the way lambdas and procs are called, so its obvious to use that as a convention.

## Installation

    $ gem install servizio

## Terminology, conventions and background

Let's clear some terms first, so that they can be used later without further explanation.

### Service

A service is a subclass of ```Servizio::Service```. It has to implement a method named ```call```. It may implement ```ActiveModel```-style validations.

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
    Some::External::Service.change_user_password(user.id, current_password, new_password)
  end
end
```

### Operation

An operation is an instance of an service. Let's assume you have a service called ```ChangePassword```, then ```operation = ChangePassword.new```

```ruby
operation = ChangePassword.new(
  user: current_user,
  current_password: "test",
  new_password: "123",
  new_password_confirmation: "123"
)
```

### Errors

Due to the fact, that ```Servizio::Service``` inludes ```ActiveModel::Validations``` we already got an error store in each derived class in form of an ```errors``` object. One point, all errors can happily reside. You can add entries there, e.g. if you call fails.

```
class ChangePassword < Servizio::Service
  attr_accessor :current_password
  ...
  
  def call
    begin
      Some::External::Service.change_user_password(user.id, current_password, new_password)
    rescue
      errors.add(:call, "Call went wrong!")
    end
  end
end
```

***Convention***
If the call fails without an result, e.g. if you are calling an external webservice and get an 500, you should set errors[:call].

### States and callbacks

Servizio knows various states an operation can be in, namely```(denied)```, ```invalid```, ```error```, ```success```. You can hook on to those states by using callbacks.

An call is assumed to be successfull, if the operation was called and ```errors``` is empty. An operation is invalid if it was tried to be called, but didn't validated.

```ruby
operation.on_invalid -> (operation) do
  render change_password_user_path
end

# there can be more than one
operation.on_invalid -> (operation) do
  log "Somebody failed to change it's password!"
end

operation.call

# will be executed immediately (if the call was successfull)
operation.on_success -> (operation) do
  flash[:success] = "Password changed!"
  redirect_to :user_path
end
```

Callbacks work like jQuery promises. You can even add callbacks after an operation was called, which will trigger the corresponding callback immediately.

### Call it magic

When you execute the call method of an operation, you actually call ```Servizio::Service:Call.call```, which in fact calls the operations call method later, but wraps it, so that callbacks can be triggered, validations can take place in front of an call and the state of the operation changes automatically.

That's the reason you don't have to do anything but implement your ```call``` method for most simple use cases. Everything else is handled for you automatically.

This is achived by using ruby's ```prepend``` in association with ```inherited```. If you want to know how it works exactly, have a look.

```ruby
module Servizio::Service::Call

  def call
    run_callbacks :call do
      if authorized? && valid?
        @called = true
        self.result = super
      end
    end
  end

  ...
end

class Servizio::Service
  require_relative "./service/call"

  def self.inherited(subclass)
    subclass.prepend(Servizio::Service::Call)
  end
  
  ...
```

## Usage

### Basic example

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

### Why is it cool?!

#### Validations included

Most operations need some kind of input to operate. If we take the ```ChangePassword``` service from the basic example, it needs
* *current_password*
* *new_password*
* *new_password_confirmation* (which must match *new_password*)

The external service which actually changes the password should only be called, if the requirements are met. Because ```Servizio::Service``` is in fact an ```ActiveModel``` class and includes ```ActiveModel::Validations``` you can write ```ActiveRecord``` style validators right into your service object. Than you can call ```valid?``` to check, if everything is ready. Or you simply hook up with an ```on_invalid``` callback.

More than this, because validations work like in ```ActiveRecord```, you can simply build forms for your services, which will exactly behave like for an ```ActiveRecord``` model. That means you can have a ```ChangePassword``` form, not an ```User``` form and it will work with gems like ```simple_form``` out-of-the-box.

#### Callbacks

There is nothing asynchronous in ```Servizio``` till now, but you can register callbacks for various states of an service object instance. Known states are ```(denied)```, ```invalid```, ```error```, ```success```. ```denied``` only works, if the service was instantiated with an ```cancan(can)```-like ability, else an operation is never denied.


## Additional readings
* http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html
* https://netguru.co/blog/service-objects-in-rails-will-help

## Contributing

1. Fork it ( https://github.com/[my-github-username]/servizio/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
