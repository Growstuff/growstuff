class AddIndexesCrops < ActiveRecord::Migration[7.2]
  def change
    add_index :alternate_names, :crop_id
    add_index :alternate_names, :creator_id
    add_index :alternate_names, :language

    add_index :comments, %i(commentable_type commentable_id)
    add_index :comments, :author_id

    add_index :crop_companions, %i(crop_a_id crop_b_id)

    add_index :crops, :creator_id
    add_index :crops, :parent_id

    add_index :follows, %i(follower_id followed_id)

    add_index :forums, :owner_id

    add_index :harvests, :crop_id
    add_index :harvests, :owner_id
    add_index :harvests, :plant_part_id

    add_index :members_roles, %i(member_id role_id)

    add_index :notifications, :sender_id
    add_index :notifications, :recipient_id

    add_index :orders_products, %i(order_id product_id)

    add_index :photo_associations, :crop_id # TODO: Is this still in use?

    add_index :photos, :owner_id
    add_index :photos, :source_id

    add_index :photos_plantings, %i(photo_id planting_id)

    add_index :plant_parts, :slug, unique: true

    add_index :plantings, :crop_id
    add_index :plantings, :garden_id
    add_index :plantings, :owner_id
    add_index :plantings, :parent_seed_id

    add_index :posts, :forum_id

    add_index :scientific_names, :crop_id
    add_index :scientific_names, :creator_id

    add_index :seeds, :owner_id
    add_index :seeds, :crop_id
    add_index :seeds, :parent_planting_id
  end
end
