class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  class << self
    def update_fields
      @update_fields ||= attribute_names
    end

    def update_fields=(fields = [])
      fields.map!(&:to_s)
      @update_fields = fields & attribute_names
    end

    def create_fields
      @create_fields ||= attribute_names
    end

    def create_fields=(fields = [])
      fields.map!(&:to_s)
      @create_fields = fields & attribute_names
    end

    def show_fields
      @show_fields ||= attribute_names
    end

    def show_fields=(fields = [])
      fields.map!(&:to_s)
      @show_fields = fields & attribute_names
    end

    def search_fields
      @search_fields ||= attribute_names
    end

    def search_fields=(fields = [])
      fields.map!(&:to_s)
      @search_fields = fields & attribute_names
    end
  end
end
