class ShortId
  attr_accessor :klass, :generation_attempts

  def initialize(klass)
    self.klass               = klass
    self.generation_attempts = 0
  end

  def generate
    until (generated_id = candidate_id) && generated_id.valid? do
      self.generation_attempts += 1
      raise 'too many hash collisions' if generation_attempts == 10
    end
    generated_id.to_s
  end

  def candidate_id
    CandidateId.new(klass)
  end

  class CandidateId
    attr_accessor :klass, :id

    def initialize(klass)
      self.klass = klass
      self.id    = generate_id
    end

    def to_s
      id
    end

    def generate_id
      Utils.random_str(6).downcase
    end

    def valid?
      !klass.exists?(short_id: id)
    end
  end
end
