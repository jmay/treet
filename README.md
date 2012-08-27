# Treet

Comparisons and transformation between trees of files and JSON blobs

The "JSON blobs" that are supported are not unlimited in structure, but must define:

* hashes, where are the values are either {hashes where the values are all scalars} or {arrays of hashes where the values are all scalars}
* or arrays of hashes as described above.

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

    hash = repo.to_hash
    repo = hash.to_repo(root)

    Treet.init(jsonfile, root) # when jsonfile contains an array which is exploded to multiple files

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

* Enforce limitation on structure depth (top-level elements can contain flat hashes or arrays, nothing else)
* refac: move diff stuff from hash.rb to Treet::Diff class, to encapsulate the structure of a diff (array of arrays); create methods for hunting for special stuff in a diff
* Check all exceptions for explicit classes
