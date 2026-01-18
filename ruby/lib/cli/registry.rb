require "singleton"

module CLI
  class Registry

    include Singleton

    COMPONENTS = [
      Component::ZshBinaryComponent,
      Component::OhMyZshComponent,
      Component::Powerlevel10kComponent,
      Component::ZgenomComponent,

      Component::BatComponent,
      Component::FdComponent,
      Component::FzfComponent,
      Component::RipgrepComponent,
      Component::FastfetchComponent,

      Component::PythonComponent,
    ].freeze

    def all
      COMPONENTS.map(&:instance)
    end

    def not_installed
      all.reject(&:installed?)
    end

    def installed
      all.select(&:installed?)
    end

    def upgradable
      all.select { |c| c.respond_to?(:upgradable?) && c.upgradable? }
    end

    def find(name)
      normalized = name.downcase.gsub(/[-_]/, "")
      all.find do |component|
        class_name = component.class.name.split("::").last
        # OhMyZshComponent -> ohmyzsh
        component_name = class_name.gsub(/Component$/, "").downcase
        component_name == normalized || component_name.include?(normalized)
      end
    end

    def find_all(names)
      names.map { |name| find(name) }.compact
    end

    def component_names
      all.map do |component|
        class_name = component.class.name.split("::").last
        class_name.gsub(/Component$/, "").gsub(/([a-z])([A-Z])/, '\1-\2').downcase
      end
    end

  end
end
