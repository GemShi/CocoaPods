module Pod
  module Generator
    # Generates Info.plist files. A Info.plist file is generated for each
    # Pod and for each Pod target definition, that requires to be built as
    # framework. It states public attributes.
    #
    class InfoPlistFile
      # @return [Target] the target represented by this Info.plist.
      #
      attr_reader :target

      # @return [Symbol] the CFBundlePackageType of the target this Info.plist
      #         file is for.
      #
      attr_reader :bundle_package_type

      # Initialize a new instance
      #
      # @param  [Target] target @see target
      #
      # @param  [Symbol] bundle_package_type @see bundle_package_type
      #
      def initialize(target, bundle_package_type: :fmwk)
        @target = target
        @bundle_package_type = bundle_package_type
      end

      # Generates and saves the Info.plist to the given path.
      #
      # @param  [Pathname] path
      #         the path where the prefix header should be stored.
      #
      # @return [void]
      #
      def save_as(path)
        contents = generate
        path.open('w') do |f|
          f.write(contents)
        end
      end

      # The version associated with the current target
      #
      # @note Will return 1.0.0 for the AggregateTarget
      #
      # @return [String]
      #
      def target_version
        if target && target.respond_to?(:root_spec)
          version = target.root_spec.version
          [version.major, version.minor, version.patch].join('.')
        else
          '1.0.0'
        end
      end

      # Generates the contents of the Info.plist
      #
      # @return [String]
      #
      def generate
        to_plist(info)
      end

      private

      def header
        <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
        PLIST
      end

      def footer
        <<-PLIST
</plist>
        PLIST
      end

      def to_plist(root)
        serialize(root, header) << footer
      end

      def serialize(value, output, indentation = 0)
        indent = ' ' * indentation
        case value
        when Array
          output << indent << "<array>\n"
          value.each { |v| serialize(v, output, indentation + 2) }
          output << indent << "</array>\n"
        when Hash
          output << indent << "<dict>\n"
          value.to_a.sort_by(&:first).each do |key, v|
            output << indent << '  ' << "<key>#{key}</key>\n"
            serialize(v, output, indentation + 2)
          end
          output << indent << "</dict>\n"
        when String
          output << indent << "<string>#{value}</string>\n"
        end
        output
      end

      def info
        info = {
          'CFBundleIdentifier' => '${PRODUCT_BUNDLE_IDENTIFIER}',
          'CFBundleInfoDictionaryVersion' => '6.0',
          'CFBundleName' => '${PRODUCT_NAME}',
          'CFBundlePackageType' => bundle_package_type.to_s.upcase,
          'CFBundleShortVersionString' => target_version,
          'CFBundleSignature' => '????',
          'CFBundleVersion' => '${CURRENT_PROJECT_VERSION}',
          'NSPrincipalClass' => '',
          'CFBundleDevelopmentRegion' => 'en',
        }

        info['CFBundleExecutable'] = '${EXECUTABLE_NAME}' if bundle_package_type != :bndl
        info['CFBundleVersion'] = '1' if bundle_package_type == :bndl

        info
      end
    end
  end
end
