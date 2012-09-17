module CustomFilters
  class TiltLayoutFilter < Rake::Pipeline::Web::Filters::TiltFilter

    attr_reader :locals

    def initialize(options={}, locals={}, context = nil, &block)
      super(&block)
      @options = options
      @locals = locals
      @context = context || Object.new
    end

    def generate_output(inputs, output)
      inputs.each do |input|
        next if input.path =~ /layout/
        out = if (template_class = Tilt[input.path])
          layout_file_name = layout_file(input) || options[:default_layout]
          layout = File.read("#{input.root}/layouts/#{layout_file_name}.liquid")
          template_class.new(nil, 1, options) { |t| layout }.render(context, locals) { FrontParser.clean(input.read) }
        else
          input.read
        end

        output.write out
      end
    end

    private

    def layout_file(input)
      content = input.dup.read
      parser = FrontParser.new(content)
      if parser.will_parse? && parser.parsed.has_key?("layout")
        parser.parsed["layout"]
      end
    end

    class FrontParser
      def initialize(content)
        @content = content
      end

      def self.clean(str)
        str.gsub(FrontMatter::REGEX, "")
      end

      def will_parse?
        FrontMatter.has_frontmatter? @content
      end

      def parsed
        @parsed ||= FrontMatter.parse @content
      end

      def inspect
        "#<FrontParser will_parse?: #{will_parse?} parsed: #{parsed}>"
      end
    end
  end
end
