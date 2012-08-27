# encoding: UTF-8

class Treet::Farm
  attr_reader :repos, :opts

  def initialize(root, opts)
    @opts = opts
    @repos = Dir.glob("#{root}/*").map do |subdir|
        Treet::Repo.new(subdir, :xref => File.basename(subdir))
    end
  end

  def export
    repos.map {|repo| repo.to_hash(:xref => opts[:xref])}
  end
end
