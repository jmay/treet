# encoding: UTF-8

class Treet::Gitfarm < Treet::Farm
  attr_reader :author

  def initialize(opts)
    super
    @author = opts[:author]
  end

  def self.plant(opts)
    farm = super
    farm.repos.each do |id, repo|
      Treet::Gitrepo.new(repo.root, opts)
    end
    Treet::Gitfarm.new(:root => farm.root, :xref => farm.xrefkey, :author => opts[:author])
  end

  def repos
    @repos_cache ||= Dir.glob("#{root}/*").each_with_object({}) do |subdir,h|
      # in a Farm we are looking for repositories under the root
      if File.directory?(subdir)
        xref = File.basename(subdir)
        h[xref] = Treet::Gitrepo.new(subdir, :xrefkey => xrefkey, :xref => xref, :author => author)
      end
    end
  end
end
