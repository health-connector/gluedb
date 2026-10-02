require 'zip'

module TradingPartnerTransforms
  # Writes in-memory files to a temp zip, adding errors.txt when there are
  # errors, and returns its path. The caller deletes the file.
  class ZipPackager
    def self.build(file_pairs, errors = [])
      z_file = Tempfile.new("trading_partner_transforms")
      zip_path = z_file.path + ".zip"
      z_file.close
      z_file.unlink
      ::Zip::File.open(zip_path, ::Zip::File::CREATE) do |zip|
        file_pairs.each do |file_name, data|
          zip.get_output_stream(file_name) do |os|
            os.write(data)
          end
        end
        if errors.any?
          zip.get_output_stream("errors.txt") do |os|
            os.write(errors.join("\n"))
          end
        end
      end
      zip_path
    end
  end
end
