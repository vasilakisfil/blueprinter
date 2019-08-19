module Blueprinter
  module Generators
    class BlueprintGenerator < ::Rails::Generators::NamedBase
      desc "Generates blueprint for ActiveRecord model with the given NAME."

      attr_accessor :options

      source_root File.expand_path("../templates", __FILE__)



      class_option :blueprints_dir, default: "app/blueprints", desc: "path to new blueprint", aliases: "-d"



      class_option :identifier, default: nil, desc: "Add an identifer to the generated blueprint, either uses :id or your specified value", aliases: "-i", banner: "id"



      class_option :fields, type: :array, default: [], desc: "Manually add specified fields"

      class_option :detect_fields, type: :boolean, default: false, desc: "Introspect on the model to set fields in the generated blueprint. Will be merged with any manually specified"



      class_option :associations, type: :array, default: [], desc: "Manually add specified associations", aliases: "-a"

      class_option :detect_associations, type: :boolean, default: false, desc: "Introspect on the model to set associations in the generated blueprint. Will be merged with any manually specified"

      class_option :dynamic_association, type: :boolean, default: false, desc: "Generate dynamic-style associations instead of default class-style"

      class_option :default_association, type: :boolean, default: false, desc: "Generated associations specify \"default: {}\""



      class_option :wrap_at, type: :numeric, default: 80, desc: "Maximum length of generated fields line", aliases: "-w"

      class_option :indentation, type: :string, default: "two", desc: "Indentation of generated file", banner: "two|four|tab"



      remove_class_option :skip_namespace

      def ensure_blueprint_dir
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      def create_blueprint
        template "blueprint.rb", File.join(path, "#{file_path}_blueprint.rb")
      end



      private

      def path
        options["blueprints_dir"]
      end

      def identifier_symbol
        if options['identifier']
           options['identifier'] == "identifier" ? :id : options['set_identifier']
        end
      end

      def fields
        fs = if options["detect_fields"]
               [].concat(options["fields"], introspected_fields)
             else
               options["fields"]
             end
        fs.reject {|f| f.blank? }.uniq
      end

      def introspected_fields
        class_name.constantize.columns_hash.keys
      end

      # split at wrap_at chars, two indentations
      def formatted_fields
        two_indents = indent * 2
        fields_string = fields.reduce([]) do |memo, f|
          if !memo.last.nil?
            now = "#{memo.last} :#{f},"
            if now.length > options["wrap_at"].to_i
              memo << ":#{f},"
            else
              memo[memo.length - 1] = now
            end
          else
            memo << " :#{f},"
          end
          memo
        end.join("\n#{two_indents}")

        fields_string[0,fields_string.length - 1]
      end

      def associations
        as = if options["detect_associations"]
               [].concat(options["associations"], introspected_associations.keys)
             else
               options["associations"]
             end
        as.reject {|f| f.blank? }.uniq
      end

      def introspected_associations
        class_name.constantize.reflections
      end

      def association_blueprint(association_name)
        style = if options["dynamic_association"]
                  association_dynamic(association_name)
                else
                  association_class(association_name)
                end
        ", blueprint: #{style}#{association_default}"
      end

      def association_dynamic(association_name)
        "->(#{association_name}) {#{association_name}.blueprint}"
      end

      def association_class(association_name)
        introspected_name = introspected_associations[association_name]&.klass&.to_s
        "#{introspected_name || association_name.camelcase}Blueprint"
      end

      def association_default
        if options["default_association"]
          ", default: {}"
        end
      end

      def indent
        user_intended = {two: "  ", four: "    ", tab:"\t"}[options["indentation"].intern]
        user_intended.nil? ? "  " : user_intended
      end
    end
  end
end
