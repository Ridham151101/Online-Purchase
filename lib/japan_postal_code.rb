require 'zlib'
require 'fileutils'

class JapanPostalCode
  DATA_PATH = 'lib/japan_postal_code/data/'

  # This method generates postal data if not already generated
  def self.generate_once(region_name, file_path)
    region_name = region_name.downcase
    marshaled_file = "#{DATA_PATH}#{region_name}.marshal.gz"

    if File.exist?(marshaled_file)
      puts "#{region_name.capitalize} postal data already exists. No need to regenerate."
    else
      puts "Generating postal data for #{region_name.capitalize}..."
      generate(region_name, file_path)
    end
  end

  # This method extracts and processes the postal data from a local file
  def self.generate(region_name, file_path)
    FileUtils.mkdir_p(DATA_PATH)
    region_name = region_name.downcase
    marshaled_file = "#{DATA_PATH}#{region_name}.marshal.gz"

    begin
      # Ensure the file exists at the provided path
      unless File.exist?(file_path)
        raise "File not found at #{file_path}. Please provide a valid file path."
      end

      # Copy the provided zip file to the data path
      download_file = "#{DATA_PATH}#{region_name}.zip"
      FileUtils.cp(file_path, download_file)

      # Unzip and process the postal code data
      system("unzip -o #{download_file} -d #{DATA_PATH}")
      puts "Unzipped #{region_name}.zip successfully."

      # Find the CSV file that was extracted
      csv_file = Dir["#{DATA_PATH}/*.CSV"].first
      if csv_file.nil?
        raise "No CSV file found in the unzipped data for #{region_name}."
      else
        puts "Found CSV file: #{csv_file}"
      end

      # Process and save data in marshaled format
      postal_data = process_data(csv_file)
      Zlib::GzipWriter.open(marshaled_file) do |f|
        Marshal.dump(postal_data, f)
      end

      puts "#{region_name.capitalize} postal data generated and saved successfully!"
    rescue StandardError => e
      puts "Error during generation: #{e.message}"
      puts e.backtrace
    end
  end

  # Process the CSV data into structured format
  def self.process_data(file)
    postal_areas = []
    File.foreach(file, encoding: 'Shift_JIS:UTF-8') do |line|
      # Parse the CSV line to extract postal code information
      data = line.split(',')
      postal_code = data[2].gsub('"', '') # Postal code
      prefecture = data[6].gsub('"', '') # Prefecture
      city = data[7].gsub('"', '') # City
      area = data[8].gsub('"', '') # Area
      postal_areas << [postal_code, prefecture, city, area]
    end
    postal_areas
  end

  # Load the marshaled file and prepare data for use
  def load(region_name)
    region_name = region_name.downcase
    marshaled_file = "#{DATA_PATH}#{region_name}.marshal.gz"

    if File.exist?(marshaled_file)
      Zlib::GzipReader.open(marshaled_file) do |f|
        @postal_areas = Marshal.load(f)
      end
      puts "Loaded postal data for #{region_name.capitalize} successfully."
    else
      raise "Postal data for #{region_name.capitalize} not found. Please run the generator."
    end
    self
  end

  # Lookup postal codes by prefix
  def lookup_by_code(postal_code)
    postal_code = postal_code.to_s.gsub(/\D/, '') # Remove non-digits
    @postal_areas.select { |area| area[0].start_with?(postal_code) }
  end
end

# Command-line argument handling for direct script execution
if __FILE__ == $0
  if ARGV.length == 3 && ARGV[0] == "generate"
    region_name = ARGV[1]
    file_path = ARGV[2]
    begin
      JapanPostalCode.generate_once(region_name, file_path)
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  else
    puts "Usage: ruby #{__FILE__} generate REGION_NAME FILE_PATH"
  end
end
