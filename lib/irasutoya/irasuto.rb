# frozen_string_literal: true

module Irasutoya
  class Irasuto
    include Modules::HasDocumentFetcher
    include Modules::HasListPageParser
    include Modules::HasShowPageParser

    attr_reader :url, :title, :description, :image_url

    def initialize(url:, title:, description:, image_url:)
      @url = url
      @title = title
      @description = description
      @image_url = image_url
    end

    class << self
      def random
        url = random_url
        document = fetch_page_and_parse(url)
        parsed = parse_show_page(document: document)

        Irasuto.new(url: url, title: parsed[:title], description: parsed[:description], image_url: parsed[:image_url])
      end

      def search(query:, page: 0)
        url = if page.zero?
                "https://www.irasutoya.com/search?q=#{CGI.escape query}"
              else
                "https://www.irasutoya.com/search?q=#{CGI.escape query}&max-results=20&start=#{page * 20}&by-date=false"
              end

        document = fetch_page_and_parse(url)
        parse_list_page(document: document).map do |parsed|
          IrasutoLink.new(title: parsed[:title], show_url: parsed[:show_url])
        end
      end

      private

      def random_api_path
        max_index = 22_208
        luck = Random.rand(max_index)
        "/feeds/posts/summary?start-index=#{luck}&max-results=1&alt=json-in-script"
      end

      def random_url
        jsonp = Net::HTTP.get('www.irasutoya.com', random_api_path)
        JSON.parse(jsonp[/{.+}/])
            .dig('feed', 'entry')
            .first
            .dig('link')
            .select { |link| link['rel'] == 'alternate' }
            .first
            .dig('href')
      end
    end
  end
end
