module CustomFilters
  # A filter that converts plates templates to javascript
  # and stores them in a defined variable.
  #
  # @example
  #   !!!ruby
  #   Rake::Pipeline.build do
  #     input "**/*.plates"
  #     output "public"
  #
  #     # Compile each plates file to JS
  #     plates
  #   end
  class PlatesFilter < Rake::Pipeline::Filter

    include Rake::Pipeline::Web::Filters::FilterWithDependencies

    class PlatesTemplateName
      def initialize filename
        @path = Pathname.new filename
      end
      def basedirname
        File.basename @path.dirname
      end
      def basename
        @path.basename ".plates"
      end
      def template_name
        "#{basedirname}/#{basename}"
      end
      def self.generate(filename)
        new(filename).template_name
      end
    end

    # @return [Hash] a hash of options for generate_output
    attr_reader :options

    # @param [Hash] options
    #   options to pass to the output generator
    # @option options [Array] :target
    #   the variable to store templates in
    # @param [Proc] block a block to use as the Filter's
    #   {#output_name_generator}.
    def initialize(options={},&block)
      # Convert .plates file extensions to .js
      block ||= proc { |input| input.sub(/\.plates|\.hbs$/, '.js') }
      super(&block)
      @options = {
          :target =>'JST',
          :wrapper_proc => proc { |source|
          "function(data,map){
            return Plates.bind(#{source}, data, map);
          }" },
          :key_name_proc => proc { |input| PlatesTemplateName.generate input.path }
        }.merge(options)
    end

    def generate_output(inputs, output)

      inputs.each do |input|
        # The name of the template is the filename, sans extension
        name = options[:key_name_proc].call(input)

        # Read the file and escape it so it's a valid JS string
        source = input.read.to_json

        # Write out a JS file, saved to target, wrapped in compiler
        output.write "#{options[:target]}['#{name}']=#{options[:wrapper_proc].call(source)}\n"
      end
    end

    private 

    def external_dependencies
      [ 'json' ]
    end
  end
end

