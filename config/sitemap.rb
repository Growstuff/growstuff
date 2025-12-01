require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://growstuff.org'
SitemapGenerator::Sitemap.sitemaps_host = ENV['SITEMAP_HOST']
SitemapGenerator::Sitemap.public_path = 'public/'
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  # static pages
  add '/community', changefreq: 'weekly', priority: 0.7
  add '/terms', changefreq: 'yearly', priority: 0.2
  add '/privacy', changefreq: 'yearly', priority: 0.2
  add '/about', changefreq: 'monthly', priority: 0.4
  add '/faq', changefreq: 'monthly', priority: 0.4
  add '/contact', changefreq: 'yearly', priority: 0.2
  add '/members', changefreq: 'weekly', priority: 0.6
  add '/gardens', changefreq: 'weekly', priority: 0.6
  add '/plantings', changefreq: 'weekly', priority: 0.6
  add '/harvests', changefreq: 'weekly', priority: 0.6
  add '/seeds', changefreq: 'weekly', priority: 0.6
  add '/crops', changefreq: 'weekly', priority: 0.6
  add '/posts', changefreq: 'daily', priority: 0.8
  add '/forums', changefreq: 'daily', priority: 0.8
  add '/photos', changefreq: 'daily', priority: 0.8

  Crop.approved.find_each do |crop|
    add crop_path(crop), lastmod: crop.updated_at
  end

  Planting.active.find_each do |planting|
    add planting_path(planting), lastmod: planting.updated_at
  end

  Seed.active.find_each do |seed|
    add seed_path(seed), lastmod: seed.updated_at
  end

  Photo.find_each do |photo|
    add photo_path(photo), lastmod: photo.updated_at
  end

  Post.find_each do |post|
    add post_path(post), lastmod: post.updated_at
  end

  Member.kept.find_each do |member|
    add member_path(member), lastmod: member.updated_at
  end
end
