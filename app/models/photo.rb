require_relative '../constants/photo_models.rb'
class Photo < ActiveRecord::Base
  belongs_to :owner, class_name: 'Member'

  Growstuff::Constants::PhotoModels.relations.each do |relation|
    has_and_belongs_to_many relation.to_sym # rubocop:disable Rails/HasAndBelongsToMany
  end

  before_destroy { all_associations.clear }

  default_scope { order("created_at desc") }

  def all_associations
    associations = []
    Growstuff::Constants::PhotoModels.relations.each do |association_name|
      associations << send(association_name.to_s).to_a
    end
    associations.flatten!
  end

  def destroy_if_unused
    destroy if all_associations.empty?
  end

  # This is split into a side-effect free method and a side-effecting method
  # for easier stubbing and testing.
  def flickr_metadata
    flickr = owner.flickr
    info = flickr.photos.getInfo(photo_id: flickr_photo_id)
    licenses = flickr.photos.licenses.getInfo
    license = licenses.find { |l| l.id == info.license }
    {
      title: info.title || "Untitled",
      license_name: license.name,
      license_url: license.url,
      thumbnail_url: FlickRaw.url_q(info),
      fullsize_url: FlickRaw.url_z(info),
      link_url: FlickRaw.url_photopage(info)
    }
  end

  def set_flickr_metadata
    update_attributes(flickr_metadata)
  end
end
