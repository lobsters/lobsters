class RandomFlags
  @@json = nil

  def self.all
    if @@json == nil
      gem = Gem::Specification.find_by_name 'world-flags'
      @@json = JSON.parse(File.read(gem.gem_dir + '/config/countries/locale_countries.en.json'))
      @@json = @@json['en'].to_a
    end

    @@json
  end

  def self.one
    RandomFlags.all.sample(1)[0]
  end
end
