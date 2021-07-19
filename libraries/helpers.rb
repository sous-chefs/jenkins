module Jenkins
  module Cookbook
    module Helpers
      def jenkins_font_packages
        if platform_family?('rhel', 'amazon')
          %w(dejavu-sans-fonts fontconfig)
        elsif platform_family?('debian')
          %w(fonts-dejavu-core fontconfig)
        end
      end

      def ulimits_to_systemd(ulimits)
        # see https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Process%20Properties

        return unless ulimits

        mapping = {
          t: 'LimitCPU',
          f: 'LimitFSIZE',
          d: 'LimitDATA',
          s: 'LimitSTACK',
          c: 'LimitCORE',
          m: 'LimitRSS',
          n: 'LimitNOFILE',
          v: 'LimitAS',
          u: 'LimitNPROC',
          l: 'LimitMEMLOCK',
          x: 'LimitLOCKS',
          i: 'LimitSIGPENDING',
          q: 'LimitMSGQUEUE',
          e: 'LimitNICE',
          r: 'LimitRTPRIO',
        }

        ulimits.map { |k, v| "#{mapping[k.to_sym]}=#{v}" }.join "\n"
      end
    end
  end
end

Chef::DSL::Recipe.include Jenkins::Cookbook::Helpers
Chef::Resource.include Jenkins::Cookbook::Helpers
