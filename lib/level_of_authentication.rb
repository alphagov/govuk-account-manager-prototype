module LevelOfAuthentication
  class << self
    def sort_levels_of_authentication(array_of_levels)
      return nil if array_of_levels.empty?

      array_of_levels.sort do |a, b|
        a.delete_prefix("level").to_i <=> b.delete_prefix("level").to_i
      end
    end

    def select_highest_level(array_of_levels)
      return nil if array_of_levels.empty?

      sort_levels_of_authentication(array_of_levels).last
    end

  end
end
