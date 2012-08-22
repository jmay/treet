# Treet

Transform between trees of files and JSON blobs

## Installation

Add this line to your application's Gemfile:

    gem 'treet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install treet

## Usage

    require 'treet'

    repo = Treet::Repo.new(directory)
    hash = Treet::Hash.new(jsonfile)

## Structures

All the nodes at the top level are mapped to subdirectories.

At the second level, arrays are converted to subdirectories named '0', '1', '2' etc. except that *for comparison purposes the order is ignored*.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

* Treet.init(json, root) to explode a JSON array-of-hashes (validate the structure first) into a set of directories (generate UUIDs for names)
* Enforce limitation on structure depth (top-level elements can contain flat hashes or arrays, nothing else)
