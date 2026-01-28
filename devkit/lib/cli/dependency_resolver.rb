module CLI
  class DependencyResolver

    # Occur when a circular dependency is detected
    class CircularDependencyError < StandardError; end

    # Return an array of components sorted by dependencies

    # @param components [Array<Component::BaseComponent>] an array of components to install
    # @return [Array<Component::BaseComponent>] an array of components sorted by dependencies
    # @raise [CircularDependencyError] when a circular dependency is detected
    def resolve(components)
      return [] if components.empty?

      all_components = collect_all_dependencies(components)

      sorted = topological_sort(all_components)

      sorted.reject do |component|
        if component.respond_to?(:installed?)
          component.installed?
        else
          component.available?
        end
      end
    end

    private

    # Collect all dependencies recursively
    #
    # @param components [Array<Component::BaseComponent>] an array of starting components
    # @return [Set<Component::BaseComponent>] a set of all related components
    def collect_all_dependencies(components)
      visited = Set.new

      components.each do |component|
        collect_dependencies_recursive(component, visited)
      end

      visited
    end

    # Collect dependencies recursively for a single component
    #
    # @param component [Component::BaseComponent] the current component
    # @param visited [Set<Component::BaseComponent>] a set of visited components
    def collect_dependencies_recursive(component, visited)
      return if visited.include?(component)

      visited.add(component)

      component.dependencies.each_value do |dep_class|
        dep_instance = dep_class.instance
        collect_dependencies_recursive(dep_instance, visited)
      end
    end

    # Use Kahn's Algorithm to sort components by dependencies
    #
    # @param components [Set<Component::BaseComponent>] a set of components to sort
    # @return [Array<Component::BaseComponent>] an array of components sorted by dependencies
    # @raise [CircularDependencyError] when a circular dependency is detected
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
