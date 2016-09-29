require 'middleman-core'
require 'middleman_dato/middleman_extension'

module Middleman
  module Paginate
    class Extension < ::Middleman::ConfigExtension
      self.resource_list_manipulator_priority = 0

      expose_to_config paginate: :paginate

      class Helper
        attr_reader :page, :total_pages, :base_path, :suffix

        def initialize(page, total_pages, base_path, suffix)
          @page = page
          @total_pages = total_pages
          @base_path = base_path
          @suffix = suffix
        end
      end

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

      def paginate(collection, base_path, template, per_page: 20, suffix: "/page/:num", locals: {}, data: {})
        pages = collection.each_slice(per_page).to_a
        num_pages = pages.size

        descriptors = []

        path_builder = ->(page) {
          "#{base_path}#{page == 1 ? '' : suffix.gsub(/:num/, page.to_s)}.html"
        }

        pages.each_with_index do |page_collection, i|
          page_num = i + 1
          next_page_num = page_num < num_pages && page_num + 1
          previous_page_num = page_num > 1 && page_num - 1

          page_path = path_builder.call(page_num)
          next_page_path = next_page_num && path_builder.call(next_page_num)
          previous_page_path = previous_page_num && path_builder.call(previous_page_num)

          meta = ::Middleman::Util.recursively_enhance(
            page_number: page_num,
            num_pages: num_pages,
            per_page: per_page,
            next_page_num: next_page_num,
            next_page_path: next_page_path,
            previous_page_num: previous_page_num,
            previous_page_path: previous_page_path
          )

          opts = {
            locals: locals.merge(items: page_collection, pager: meta),
            data: data
          }

          descriptors << Middleman::Sitemap::Extensions::ProxyDescriptor.new(
            Middleman::Util.normalize_path(page_path),
            Middleman::Util.normalize_path(template),
            opts
          )
        end

        CollectionDescriptor.new(descriptors)
      end
    end
  end
end
