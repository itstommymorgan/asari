# Asari

## Description

Asari is a Ruby wrapper for AWS CloudSearch, with optional ActiveRecord support
for easy integration with your Rails apps.

#### Why Asari?

"Asari" is Japanese for "rummaging search." Seemed appropriate.

## Usage

#### Your Search Domain

Amazon Cloud Search will give you a Search Endpoint and Document Endpoint.  When specifying your search domain in Asari omit the search- for your search domain.  For example if your search endpoint is "search-beavis-er432w3er.us-east-1.cloudsearch.amazonaws.com" the search domain you use in Asari would be "beavis-er432w3er".  Your region is the second item.  In this example it would be "us-east-1".

#### Basic Usage

    asari = Asari.new("my-search-domain-asdfkljwe4") # CloudSearch search domain
    asari.add_item("1", { :name => "Tommy Morgan", :email => "tommy@wellbredgrapefruit.com"})
    asari.search("tommy") #=> ["1"] - a list of document IDs
    asari.search("tommy", :rank => "name") # Sort the search
    asari.search("tommy", :rank => ["name", :desc]) # Sort the search descending
    asari.search("tommy", :rank => "-name") # Another way to sort the search descending

#### Sandbox Mode

Because there is no "local" version of CloudSearch, and search instances can be
kind of expensive, you shouldn't have to have a development version of your
index set up in order to use Asari. Because of that, Asari has a "sandbox" mode
where it does nothing with add/update/delete requests and just returns an empty
collection for any searches. This sandbox mode is enabled by default - any time
you want to actually connect to the search index, just do the following:

    Asari.mode = :production

You can turn the sandbox back on, if you like, by setting the mode to `:sandbox`
again.
    
#### Pagination

Asari defaults to a page size of 10 (because that's CloudSearch's default), but
it allows you to specify pagination parameters with any search:

    asari.search("tommy", :page_size => 30, :page => 10)

The results you get back from Asari#search aren't actually Array objects,
either: they're Asari::Collection objects, which are (currently) API-compatible
with will\_paginate:
  
    results = asari.search("tommy", :page_size => 30, :page => 10)
    results.total_entries #=> 5000
    results.total_pages   #=> 167
    results.current_page  #=> 10
    results.offset        #=> 300
    results.page_size     #=> 30

#### ActiveRecord

By default the ActiveRecord module for Asari is not included in your project.  To use it you will need to require it via 

    require 'asari/active_record'

You can take advantage of that module like so:

    class User < ActiveRecord::Base
      include Asari::ActiveRecord

      #... other stuff...

      asari_index("search-domain-for-users", [:name, :email, :twitter_handle, :favorite_sweater])
    end

This will automatically set up before\_destroy, after\_create, and after\_update
hooks for your AR model to keep the data in sync with your CloudSearch index -
the second argument to asari\_index is the list of fields to maintain in the
index, and can represent any function on your AR object. You can then interact
with your AR objects as follows:

    # Klass.asari_find returns a list of model objects in an
    # Asari::Collection... 
    User.asari_find("tommy") #=> [<User:...>, <User:...>, <User:...>]
    User.asari_find("tommy", :rank => "name")
    
    # or with a specific instance, if you need to manually do some index
    # management...
    @user.asari_add_to_index
    @user.asari_update_in_index
    @user.asari_remove_from_index

You can also specify a :when option, like so:

    asari_index("search-domain-for-users", [:name, :email, :twitter_handle,
    :favorite_sweater], :when => :indexable)

or
    
    asari_index("search-domain-for-users", [:name, :email, :twitter_handle,
    :favorite_sweater], :when => Proc.new { |user| !user.admin && user.indexable })

This provides a way to mark records that shouldn't be in the index. The :when
option can be either a symbol - indicating a method on the object - or a Proc
that accepts the object as its first parameter. If the method/Proc returns true
when the object is created, the object is indexed - otherwise it is left out of
the index. If the method/Proc returns true when the object is updated, the
object is indexed - otherwise it is deleted from the index (if it has already
been added). This lets you be sure that you never have inappropriate data in
your search index.

Because index updates are done as part of the AR lifecycle by default, you also
might want to have control over how Asari handles index update errors - it's
kind of problematic, if, say, users can't sign up on your site because
CloudSearch isn't available at the moment. By default Asari just raises these
exceptions when they occur, but you can define a special handler if you want
using the asari\_on\_error method:

    class User < ActiveRecord::Base
      include Asari::ActiveRecord

      asari_index(... )

      def self.asari_on_error(exception)
        Airbrake.notify(...)
        true
      end
    end

In the above example we decide that, instead of raising exceptions every time,
we're going to log exception data to Airbrake so that we can review it later and
then return true so that the AR lifecycle continues normally.

#### AWS Region

By default, Asari assumes that you're operating in us-east-1, which is probably
not a helpful assumption for some of you. To fix this, either set the
`aws_region` property on your raw Asari object:

    a = Asari.new("my-search-domain")
    a.aws_region = "us-west-1"

...Or provide the `:aws_region` option when you call `asari_index` on an
ActiveRecord model:

    class User < ActiveRecord::Base
      include Asari::ActiveRecord

      asari_index("my-search-domain",[field1,field2], :aws_regon => "us-west-1")

      ...
    end

## Get it

It's a gem named asari. Install it and make it available however you prefer.

Asari is developed on ruby 1.9.3, and the ActiveRecord portion has been tested
with Rails 3.2. I don't know off-hand of any reasons that it shouldn't work in
other environments, but be aware that it hasn't (yet) been tested.

## Contributions

If Asari interests you and you think you might want to contribute, hit me up on
Github. You can also just fork it and make some changes, but there's a better
chance that your work won't be duplicated or rendered obsolete if you check in
on the current development status first.

Gem requirements/etc. should be handled by Bundler.

### Contributors

* [Emil Soman](https://github.com/emilsoman "emilsoman on Github")
* [Chris Vincent](https://github.com/cvincent "cvincent on Github")

## License
Copyright (C) 2012 by Tommy Morgan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
          
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
