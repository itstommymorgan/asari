# Asari 1.0-Pre

## Description

[![Build Status](https://travis-ci.org/lgleasain/asari.svg?branch=master)](https://travis-ci.org/lgleasain/asari)

Asari is a Ruby wrapper for AWS CloudSearch, with optional ActiveRecord support
for easy integration with your Rails apps.

Note:  This version is currently under heavy development.  If you want a stable version please look aththe master branch.

#### Why Asari?

"Asari" is Japanese for "rummaging search." Seemed appropriate.

## Usage

#### API Version

Asari defaults to using the 2011-02-01 version of the API.  If you want to use the 2013-01-01 version set the CLOUDSEARCH_API_VERSION environment variable.

#### Your Search Domain

Amazon Cloud Search will give you a Search Endpoint and Document Endpoint.  When specifying your search domain in Asari omit the search- for your search domain.  For example if your search endpoint is "search-beavis-er432w3er.us-east-1.cloudsearch.amazonaws.com" the search domain you use in Asari would be "beavis-er432w3er".  Your region is the second item.  In this example it would be "us-east-1".

#### Basic Usage

    asari = Asari.new("my-search-domain-asdfkljwe4") # CloudSearch search domain
    asari.add_item("1", { :name => "Tommy Morgan", :email => "tommy@wellbredgrapefruit.com"})
    asari.search("tommy") #=> ["1"] - a list of document IDs
    asari.search("tommy", :rank => "name") # Sort the search
    asari.search("tommy", :rank => ["name", :desc]) # Sort the search descending
    asari.search("tommy", :rank => "-name") # Another way to sort the search descending


#### Boolean/Structured Compound Query Usage

    asari.search(filter: { and: { title: "donut", type: "cruller" }})
    asari.search("boston creme", filter: { and: { title: "donut", or: { type: "cruller|twist" }}}) # Full text search and nested boolean logic 2011-02-01 API only

For more information on how to use Cloudsearch boolean queries (2011-02-01), [see the
documentation.](http://docs.aws.amazon.com/cloudsearch/latest/developerguide/booleansearch.html)
For more information on how to use Cloudsearch structured compound queries (2013-01-01), [see the documentation.](http://docs.aws.amazon.com/cloudsearch/latest/developerguide/searching-compound-queries.html)

### Geospatial Query Usage

#### Api Version 2011-02-01

While Cloudsearch does not natively support location search, you can implement rudimentary location search by representing latitude and longitude as integers in your search domain. Asari has a Geography module you can use to simplify the conversion of latitude and longitude to cartesian coordinates as well as the generation of a coordinate box to search within. Asari's Boolean Query syntax can then be used to search within the area. Note that because Cloudsearch only supports 32-bit unsigned integers, it is only possible to store latitude and longitude to two place values. This means very precise search isn't possible using Asari and Cloudsearch. 

    coordinates = Asari::Geography.degrees_to_int(lat: 45.52, lng: 122.68)
      #=> { lat: 2506271416, lng: 111298648 }
    asari.add_item("1", { name: "Tommy Morgan", lat: coordinates[:lat], lng: coordinates[:lng] })
      #=> nil
    coordinate_box = Asari::Geography.coordinate_box(lat: 45.2, lng: 122.85, meters: 7500)
      #=> { lat: 2505521415..2507021417, lng: 111263231..111334065 } 
    asari.search("tommy", filter: { and: coordinate_box }
      #=> ["1"] = a list of document IDs

For more information on how to use Cloudsearch for location search, [see the
documentation.](http://docs.aws.amazon.com/cloudsearch/latest/developerguide/geosearch.html)

#### Api Version 2013-01-01

This version has native geospacial support but will need additional integration to get it into Asari.  Pull requests are welcome :)

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

#### Retrieving Data From Index Fields

By default Asari only returns the document id's for any hits returned from a search. 
If you have result_enabled a index field you can have asari resturn that field in the
result set without having to hit a database to get the results.  Simply pass the 
:return_fields option with an array of fields

    results = asari.search "Beavis", :return_fields => ["name", "address"]

The result will look like this

    {"23" => {"name" => "Beavis", "address" => "One CNN Center,  Atlanta"},
    "54" => {"name" => "Beavis C", "address" => "Cornholio Way, USA"}}

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

While having asari auto index,  delete and update records can be handy,  it doesn't provide a great failover mechanism if you are having communication issues between your system and cloud search.  To enable delayed indexing add the following before requiring 'asari/active_record'.  

    class Asari
      module ActiveRecord
        DELAYED_ASARI_INDEX = true
      end
    end

You can then manually trigger deletes,  adds and updates by calling asari_remove_from_index,  asari_add_to_index and asari_update_in_index on your model.

We also have support for batching updates by calling asari_add_items on a asari model object.  

    user1 = User.create
    user2 = User.create
    User.asari_add_items [user1, user2, user3]

A batch delete_items can be accomplished via asari_remove_item on a asari model object

    User.asari_remove_items [1, 2, 8]

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

      asari_index("my-search-domain",[field1,field2], :aws_region => "us-west-1")

      ...
    end

## ActiveAsari

Full Active Record Integration with Asari along with migration-like indexing.  This makes using Amazon Cloud Search a lot easier in your rails application.

#### Configuration

Include the gem in your project.

  gem 'active_asari'

In your application.rb file or in the main part of your rack app.  NOTE:  The ActiveAsari.configure method needs a directory to be passed to it.  It will look for the configuration files and load them from this location.

    AWS.config({:access_key_id => 'your Amazon key id', :secret_access_key => 'your Amazon secret key'})
    require 'active_asari'
    ACTIVE_ASARI_CONFIG, ACTIVE_ASARI_ENV = ActiveAsari.configure(File.dirname(__FILE__))
    require 'active_asari/active_record'
  
There are two configuration files that active_asari looks for.  First,  active_asari_env.yml.  Right now this file is used to configure the prefix to use for your domains.  Prefixing was added so that you can have domains for multiple environments under one amazon account without having them stomp on each other.  Here is an example of a active_asari_env.yml file.

    development:
      domain_prefix: dev
    staging:
      domain_prefix: staging

When you are in a test environment active_asari overlays are disabled.  Right now the recommended way of testing asari calls is via mocking.

#### Your Domain

Domains are collections of data that you can store.  ActiveAsari has taken the approach of associating a activerecord table with a domain.  So if you have a talble called events then you might create a domain of the same name.  Domain objects are specified in the active_asari_config.yml file.  Below is an example of a file.

    TestModel:
      name: 
        index_field_type: text
        search_enabled: true
      amount: 
        index_field_type: uint
        search_enabled: true
      last_updated:
        index_field_type: uint
        search_enabled: false
      bee_larvae_type:
        index_field_type: literal
    HoneyBadger:
      name:
        index_field_type: text 

The domain is the top most element in the structure.  The example above specifies two domains.  The first one has indexes for name,  amount,  last_updated and bee_larvae_type.  All active_asari fields are result enabled to allow you to retrive the result values from Amazon Cloud search.  The index_field_type specifies the Amazon Cloud Search unit type.  search_enabled specifies your ability to search on a field.  text fields are always searchable,  uint are configurable but default to searchable and literals need to be enabled if you want to be able to search them.  

The ActiveAsari::Migrations class has methods to 'migrate' your cloud search instance to have domains with indexes specified in your config file.  We have a todo to add rake tasks to the gem.  In the meantime you can all migrate_all to create everything in your configuration file or migrate_domain to migrate one domain.  Both of these commands also apply to access policies you specified in your env file.  When the domain is created,  the prefix you specified is added to the domain and it is uncased similar to rails but instead of using underscores it uses -.  For example HoneyBadger in the development environment with a prefix of dev would create a domain called dev-honey-badger.

#### Your Models

Any model can be associated with a ActiveAsari Object.  This is done by adding the following three lines to the beginning of your model class.

    include ActiveAsari::ActiveRecord
    include Asari::ActiveRecord if !env_test?
    active_asari_index 'YourDomain'

You would substitute the appropriate domain specified in your config file.  The !env_test option was the only way to not have ActiveAsari not interfere with tests.  We would welcome pull requests to make this cleaner.

Once you have this in your model,  and have run your migrations all update,  create and deletes to the model in a non_test environment will automatically be performed in AmazonCloud search keeping the two environments in sync.

#### Searching 

Searching is done via ActiveAsari.active_asari_search.  IE:

    ActiveAsari.active_asari_search 'HoneyBadger', 'name:beavis',  :query_type => :boolean

The query_type allows you to specify if you want to do a boolean or regular query.  All other options are passed directly to asari,  so see the asari gem for documentation on how to use it.  Results are automatically returned in a hash of objects indexed by the document_id.  The object contains a raw_result accessor along with accessors for all returned fields in the hash.  So...

    my_result = ActiveAsari.active_asari_search 'HoneyBadger', 'beavis'
    my_result['6'].name.should include 'beavis'

Search parameters are passed directly to Amazon Cloud Search.  See it's documentation for otpions,  syntax etc..

## Get it

It's a gem named asari. Install it and make it available however you prefer.

Asari is developed on ruby 2.1.2, and the ActiveRecord portion has been tested
with Rails 4.1.  It has also been tested on 1.9.x and JRuby.

## Roadmap

Two features that we want to get into Asari are facet support and suport for native geo-coordinate support in version 2013-01-01 of the Amazon API.  Pull requests are always welcome to get this out.

## Contributions

If Asari interests you and you think you might want to contribute, hit us up on
Github. You can also just fork it and make some changes, but there's a better
chance that your work won't be duplicated or rendered obsolete if you check in
on the current development status first.

Gem requirements/etc. should be handled by Bundler.

Also,  we have maintained close to 100% test coverage on the project.  Your pull request will have a much better chance of being accepted if you write specs for it.

### Contributors

* [Lance Gleason](https://github.com/lgleasain "lgleasain on GitHub")
* [Emil Soman](https://github.com/emilsoman "emilsoman on GitHub")
* [Chris Vincent](https://github.com/cvincent "cvincent on GitHub")
* [Kyle Meyer](https://github.com/kaiuhl "kaiuhl on GitHub")
* [Brentan Alexander](https://github.com/brentan "brentan on GitHub")
* [Playon Sports](http://company.playonsports.com/)
* [Treehouse](http://teamtreehouse.com/)

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
