class Catalog < ApplicationRecord
  self.create_fields = [:name, :space_id, :sort]
  self.update_fields = [:name, :space_id, :sort]
  self.show_fields = [:id, :name, :space_id, :sort]
  self.search_fields = [:name]

  has_many :ft_flows, class_name: 'FtFlow', primary_key: 'id', foreign_key: 'catalog'
  has_many :meta_datasources, dependent: :nullify
  has_many :meta_hosts, dependent: :nullify


  def self.default_catalog(space_type = "FLOW")
    space = Space.where(space_type: space_type).where(name: "Default").first
    if space.nil?
      space = Space.create(name: "Default", space_type: space_type, sort: 0)
    end
    catalog = Catalog.where(space_id: space.id).where(name: "Default").first
    if catalog.nil?
      catalog = Catalog.create(name: "Default", space_id: space.id, sort: 0)
    end
    catalog
  end

  def self.default_catalog_id(space_type = "FLOW")
    default_catalog(space_type).id
  end

  def html_json
    as_json(only: Catalog.show_fields)
  end
end
