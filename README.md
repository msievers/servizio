# Servizio

[![Build Status](https://travis-ci.org/msievers/servizio.svg?branch=master)](https://travis-ci.org/msievers/servizio)
[![Test Coverage](https://codeclimate.com/github/msievers/servizio/badges/coverage.svg)](https://codeclimate.com/github/msievers/servizio)
[![Code Climate](https://codeclimate.com/github/msievers/servizio/badges/gpa.svg)](https://codeclimate.com/github/msievers/servizio)
[![Dependency Status](https://gemnasium.com/msievers/servizio.svg)](https://gemnasium.com/msievers/servizio)

Servizio is a gem to support you creating service objects. It was created after I read a blog post about [service objects](http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html) from [Philippe Creux](https://twitter.com/pcreux). Realy great post, check it out.

I liked the ideas presented there, so I began to use them. Quickly I realised, that combining the basic concepts presented in this post with something like ```ActiveModel``` would be awesome. So there was ```Servizio```.  

## TL;DR

Servizio is a class you can derive your service classes from. It includes ```ActiveModel::Model``` and ```ActiveModel::Validations``` and wraps the ```call``` method of the derived class by prepending some code to the derived class' singleton class. The main purpose is to provide some conventions for and to ease the creation of service classes.

```ruby
class MyService < Servizio::Service
  attr_accessor :summands

  validates_presence_of :summands

  def call
    summands.reduce(:+)
  end
end

# create an instance of a service (a.k.a. an operation)
operation = MyService.new(operands: [1,2,3])

# call the operation and get it's result
operation.call.result # => 6
```

## Additional readings
* http://brewhouse.io/blog/2014/04/30/gourmet-service-objects.html
* https://netguru.co/blog/service-objects-in-rails-will-help

## Contributing

1. Fork it ( https://github.com/msievers/servizio/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
