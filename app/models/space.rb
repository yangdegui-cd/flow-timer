class Space < ApplicationRecord
  self.update_fields = %w[name sort]
  self.create_fields = %w[name space_type sort]
  self.show_fields = %w[id name space_type sort]
  self.search_fields = %w[name]

  has_many :catalogs, -> { order(sort: :asc) }, dependent: :destroy

  enum space_type: {
    flow: "FLOW",
    task: "TASK",
    meta_host: "META_HOST",
    meta_datasource: "META_DATASOURCE",
    meta_cos: "META_COS"
  }

  def self.get_all(type = space_type.flow)
    where(space_type: type).includes(:catalogs).order(sort: :asc).map(&:html_json)
  end

  def html_json
    as_json(only: Space.show_fields).merge({catalogs: catalogs.map{|c| c.as_json(only: Catalog.show_fields)}})
  end
end
