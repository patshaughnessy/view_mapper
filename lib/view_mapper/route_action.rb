module ViewMapper
  module RouteAction

    module Base
      def route_code(route_options)
        "map.#{route_options[:name]} '#{route_options[:path]}', :controller => '#{route_options[:controller]}', :action => '#{route_options[:action]}'"
      end
      def route_file
        'config/routes.rb'
      end
    end

    module Create
      def route(route_options)
        sentinel = 'ActionController::Routing::Routes.draw do |map|'
        logger.route route_code(route_options)
        gsub_file route_file, /(#{Regexp.escape(sentinel)})/mi do |m|
            "#{m}\n  #{route_code(route_options)}\n"
        end
      end
    end

    module Destroy
      def route(route_options)
        logger.remove_route route_code(route_options)
        to_remove = "\n  #{route_code(route_options)}"
        gsub_file route_file, /(#{to_remove})/mi, ''
      end
    end

  end
end
