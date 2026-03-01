# frozen_string_literal: true

require 'aws-sdk-s3'

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://growstuff.org'

SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  ENV['S3_SITEMAP_BUCKET'],
  access_key_id:     ENV['S3_ACCESS_KEY'],
  secret_access_key: ENV['S3_SECRET_KEY'],
  region:            ENV.fetch('S3_AWS_REGION', 'us-east-1')
)

SitemapGenerator::Sitemap.create do
  # Add static pages
  add '/about', changefreq: 'monthly'
  add '/community', changefreq: 'monthly'
  add '/contact', changefreq: 'monthly'

  # Add crops
  Crop.approved.find_each do |crop|
    add crop_path(crop), lastmod: crop.updated_at
  end

  # Add members
  Member.kept.find_each do |member|
    add member_path(member), lastmod: member.updated_at
  end

  # Add plantings
  Planting.active.find_each do |planting|
    add planting_path(planting), lastmod: planting.updated_at
  end

  # Add seeds
  Seed.active.find_each do |seed|
    add seed_path(seed), lastmod: seed.updated_at
  end

  # Add harvests
  Harvest.find_each do |harvest|
    add harvest_path(harvest), lastmod: harvest.updated_at
  end

  # Add posts
  Post.find_each do |post|
    add post_path(post), lastmod: post.updated_at
  end

  # Add photos
  Photo.find_each do |photo|
    add photo_path(photo), lastmod: photo.updated_at
  end
end
