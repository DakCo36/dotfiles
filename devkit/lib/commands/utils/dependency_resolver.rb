module Commands
  class DependencyResolver

    class CircularDependencyError < StandardError; end

    # @param components [Array<Component::BaseComponent>] an array of components to install
    # @param force [Boolean] if true, include already installed components
    # @return [Array<Component::BaseComponent>] an array of components sorted by dependencies
    # @raise [CircularDependencyError] when a circular dependency is detected
    def resolve(components, force: false)
      return [] if components.empty?

      all_components = collect_all_dependencies(components)

      sorted = topological_sort(all_components)

      sorted.reject! { |c| c.is_a?(Component::RequiredComponent) }

      return sorted.select { |c| c.respond_to?(:install!) } if force

      sorted.reject(&:installed?)
    end

    private

    def collect_all_dependencies(components)
      visited = Set.new

      components.each do |component|
        collect_dependencies_recursive(component, visited)
      end

      visited
    end

    def collect_dependencies_recursive(component, visited)
      return if visited.include?(component)

      visited.add(component)

      component.dependencies.each_value do |dep_class|
        dep_instance = dep_class.instance
        collect_dependencies_recursive(dep_instance, visited)
      end
    end

    def topological_sort(components)
      components_array = components.to_a

      class_to_instance = {}
      components_array.each do |comp|
        class_to_instance[comp.class] = comp
      end

      in_degree = Hash.new(0)
      components_array.each do |component|
        component.dependencies.each_value do |dep_class|
          in_degree[component] += 1 if class_to_instance.key?(dep_class)
        end
      end

      queue = components_array.select { |c| in_degree[c] == 0 }
      result = []

      until queue.empty?
        current = queue.shift
        result << current

        components_array.each do |component|
          if component.dependencies.values.include?(current.class)
            in_degree[component] -= 1
            queue << component if in_degree[component] == 0
          end
        end
      end

      if result.size < components_array.size
        unprocessed = components_array - result
        cycle_names = unprocessed.map(&:display_name).join(", ")
        raise CircularDependencyError,
              "순환 의존성이 감지되었습니다: #{cycle_names}"
      end

      result
    end

  end
end
