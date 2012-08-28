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

## Usage - Command Line

    treet expand [path] [jsonfile]
    treet explode [jsonfile] [rootdir]
    treet import [rootdir] [xrefkey]

## Usage - API

    require 'treet'

    hash = Treet::Hash.new(jsonfile)
    repo = Treet::Repo.new(directory)
    farm = Treet::Farm.new(rootdir, :xref => 'label')

    hash = repo.to_hash
    repo = hash.to_repo(root)
    hash = farm.export

    Treet.init(jsonfile, root) # when jsonfile contains an array which is exploded to multiple files

## Concepts

A *repo* is a directory that contains other files & directories. Any text files in this tree structure must contain JSON-formatted data.

A *farm* is a directory containing one or more repos. When a farm is exported to JSON, each record is augmented with an xref value that contains the root filename of that repo.

For example:

    farm = Treet::Farm.new(rootdir, :xref => 'keycode')
    puts farm.export

should produce something like:

    {
      "subdir1": {
        "field": "value"
      },
      "subdir2": {
        "field": "value",
        "field2": "value2"
      },
      "xref": {
        "keycode": "repo-dir-name"
      }
    }

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
