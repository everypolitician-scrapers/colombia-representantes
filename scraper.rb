#!/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'scraped'
require 'scraperwiki'
require 'irb'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    member_urls.map do |url|
      Scraped::Scraper.new(url => MemberPage).scraper.to_h
    end
  end

  private

  def member_urls
    noko.css('.namereplist a/@href').map(&:text)
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.split('/').last
  end

  field :name do
    noko.css('title').text.split('|').first.tidy
  end

  field :image do
    noko.css('.field--name-field-imagen-representante img/@src').text
  end

  field :email do
    noko.css('.field--name-field-correorepresentante a').text.tidy
  end

  field :area do
    noko.css('.field--name-field-circunscripcion-territoria').text.tidy
  end

  field :party do
    noko.css('.partpolit').text.tidy
  end

  field :source do
    url
  end
end

url = 'http://www.camara.gov.co/representantes'
Scraped::Scraper.new(url => MembersPage).store(:members)
