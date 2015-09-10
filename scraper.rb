#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.listado_proyectos a[href*="/representantes/"]/@href').each do |href|
    link = URI.join url, href
    scrape_person(link)
  end
end

def scrape_person(url)
  noko = noko_for(url)

  box = noko.css('#contenido_comision')
  rhs = noko.css('.contenido_der')

  data = { 
    id: url.to_s[/idrpr=(\d+)/, 1],
    name: box.css('.contentheading').text.tidy,
    party: box.xpath('.//td[contains(.,"Partido o Movimiento")]/following-sibling::td').text.tidy,
    area: box.xpath('.//td[contains(.,"Circunscripción")]/following-sibling::td').text.tidy,
    image: rhs.css('.redes_sociales img/@src').first.text,
    email: rhs.css('a[href*="mailto:"]/@href').text.sub('mailto:',''),
    tel: rhs.xpath('.//td[contains(.,"Teléfono")]/following-sibling::td').text.tidy,
    facebook: rhs.css('a[href*="facebook"]/@href').text,
    twitter: rhs.css('a[href*="twitter"]/@href').text,
    term: 2014,
    source: url.to_s,
  }
  data[:image] = URI.join(url, URI.encode(URI.decode(data[:image]))).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.camara.gov.co/portal2011/representantes/honorables-representantes?option=com_representantes&view=representantes&limit=0')
