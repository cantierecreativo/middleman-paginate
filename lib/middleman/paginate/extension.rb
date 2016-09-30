require 'middleman-core'
require 'middleman_dato/middleman_extension'

module Middleman
  module Paginate
    class Extension < ::Middleman::ConfigExtension
      self.resource_list_manipulator_priority = 0

      expose_to_config paginate: :paginate

      class CollectionDescriptor
        attr_reader :descriptors

        def initialize(descriptors)
          @descriptors = descriptors
        end

        def execute_descriptor(app, sum)
          descriptors.reduce(sum) do |sum, descriptor|
            descriptor.execute_descriptor(app, sum)
          end
        end
      end

      class Pager
        attr_reader :current_page, :total_pages, :per_page

        def initialize(base_path, suffix, current_page, total_pages, per_page)
          @base_path = base_path
          @suffix = suffix
          @current_page = current_page
          @total_pages = total_pages
          @per_page = per_page
        end

        def next_page
          current_page < total_pages && current_page + 1
        end

        def previous_page
          current_page > 1 && current_page - 1
        end

        def page_path(page = current_page)
          "#{@base_path}#{page == 1 ? '' : @suffix.gsub(/:num/, page.to_s)}.html"
        end
      end

      def paginate(collection, base_path, template, per_page: 20, suffix: "/page/:num", locals: {}, data: {})
        pages = collection.each_slice(per_page).to_a

        descriptors = []

        pages.each_with_index do |page_collection, i|
          pager = Pager.new(base_path, suffix, i + 1, pages.size, per_page)

          opts = {
            locals: locals.merge(items: page_collection, pager: pager),
            data: data
          }

          descriptors << Middleman::Sitemap::Extensions::ProxyDescriptor.new(
            Middleman::Util.normalize_path(pager.page_path),
            Middleman::Util.normalize_path(template),
            opts
          )
        end

        CollectionDescriptor.new(descriptors)
      end
    end
  end
end
