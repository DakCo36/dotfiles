require "singleton"

module Commands
  class Registry

    include Singleton

    @registered_components = []
    @loaded = false

    def self.register(component_class)
      @registered_components << component_class unless @registered_components.include?(component_class)
    end

    def self.registered_components
      @registered_components
    end

    def self.load_components!
      return if @loaded

      components_dir = File.expand_path("../../../components", __FILE__)
      skip_files = %w[base.rb required_component.rb installable_component.rb configuration.rb]

      priority_dirs = %w[prerequisites shell font language editors]

      priority_dirs.each do |dir|
        Dir[File.join(components_dir, dir, "*.rb")].sort.each do |file|
          require file
        end
      end

      Dir[File.join(components_dir, "**", "*.rb")].sort.each do |file|
        basename = File.basename(file)
        next if skip_files.include?(basename)

        require file
      end

      @loaded = true
    end

    def self.loaded?
      @loaded
    end

    def all
      self.class.load_components! unless self.class.loaded?
      self.class.registered_components.map(&:instance)
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
