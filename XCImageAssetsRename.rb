require 'json'
require 'fileutils'

# NameOfImage_29x29_minimum-system-version=7.0_@2x~universal-portrait

class XCImageAssetsCleaner

    CONTENTS_FILENAME = 'Contents.json'
    IMAGES_FOLDER_SUFFIX = '.imageset'

    CONTENTS_IMAGES_KEY = 'images'

    IMAGES_SCALE_KEY = 'scale'
    IMAGES_FILENAME_KEY = 'filename'
    IMAGES_SIZE_KEY = 'size'
    IMAGES_IDIOM_KEY = 'idiom'
    IMAGES_ORIENTATION_KEY = 'orientation'

    KnownSuffixKeys = [IMAGES_SCALE_KEY, IMAGES_FILENAME_KEY, IMAGES_SIZE_KEY, IMAGES_IDIOM_KEY, IMAGES_ORIENTATION_KEY]

    def initialize
        @renamedFiles = {}
    end

    def base_image_name_for_directory directoryString
        imageName = directoryString.lines('/').last

        if imageName.end_with?(IMAGES_FOLDER_SUFFIX)
            imageName = imageName[0..-(IMAGES_FOLDER_SUFFIX.length + 1)]
        end

        return imageName
    end

    def unknown_suffixes imageDict
        unknownSuffixes = []

        imageDict.each do |key, val|
            if !KnownSuffixKeys.include?(key)
                unknownSuffixes << "#{key}=#{val}"
            end
        end

        return unknownSuffixes
    end

    def image_suffixes imageDict
        imageSuffixes = ""

        size = imageDict[IMAGES_SIZE_KEY]
        if size
            imageSuffixes = imageSuffixes + "_#{size}_"
        end

        unknownSuffixes = unknown_suffixes imageDict
        if unknownSuffixes.length > 0
            imageSuffixes = imageSuffixes + unknownSuffixes.join('_') + '_'
        end

        scale = imageDict[IMAGES_SCALE_KEY]
        if scale
            imageSuffixes = imageSuffixes + "@#{scale}"
        end

        idiom = imageDict[IMAGES_IDIOM_KEY]
        if idiom
            imageSuffixes = imageSuffixes + "~#{idiom}"
        end

        orientation = imageDict[IMAGES_ORIENTATION_KEY]
        if orientation
            imageSuffixes = imageSuffixes + "-#{orientation}"
        end

        return imageSuffixes
    end

    def image_name imageDict, directoryString
        baseImageName = base_image_name_for_directory directoryString
        imageSuffixes = image_suffixes imageDict
        return baseImageName + imageSuffixes
    end

    def replace_first_occurrence_in_file oldText, newText, fileString
        allText = File.read(fileString)
        newText = allText.sub(/#{oldText}/, newText)
        File.open(fileString, "w") { |file| file.puts newText }
    end

    def clean_image_dict imageDict, directoryString
        if imageDict[IMAGES_FILENAME_KEY] && imageDict[IMAGES_SCALE_KEY]
            oldFilename = imageDict[IMAGES_FILENAME_KEY]
            oldFileString = "#{directoryString}/#{oldFilename}"

            imageName = image_name imageDict, directoryString
            fileExt = oldFilename.lines('.').last

            newFilename = "#{imageName}.#{fileExt}"
            newFileString = "#{directoryString}/#{newFilename}"

            if @renamedFiles.has_key? oldFileString
                renamedFileString = @renamedFiles[oldFileString]
                FileUtils.cp(renamedFileString, newFileString)
            else
                
                begin
                    File.rename(oldFileString, newFileString)
                rescue SystemCallError => err
                    if err.errno == Errno::ENOENT::Errno
                        puts "File not be found: #{oldFileString}"
                        puts "Named in #{directoryString}/#{CONTENTS_FILENAME}"
                        puts
                    else
                        raise
                    end
                end

                @renamedFiles[oldFileString] = newFileString
            end

            replace_first_occurrence_in_file(oldFilename, newFilename, "#{directoryString}/#{CONTENTS_FILENAME}")
        else
            puts "Image data does not include filename:"
            puts "#{directoryString}/#{CONTENTS_FILENAME}"
            puts imageDict
            puts
        end
    end

    def clean_images_in directoryString
        directoryString.chomp!('/')
        contents = JSON.parse(File.read("#{directoryString}/#{CONTENTS_FILENAME}"))
        contents[CONTENTS_IMAGES_KEY].each do |imageDict|
            clean_image_dict imageDict, directoryString
        end
    end

    def clean_directory directoryString
        directoryString.chomp!('/')
        if File.exist?("#{directoryString}/#{CONTENTS_FILENAME}")
            clean_images_in directoryString
        else
            Dir.glob("#{directoryString}/*/").each do |subdir|
                clean_directory subdir
            end
        end
    end

    def clean xcassets
        Dir.glob("#{xcassets}/*/").each do |subdir|
            clean_directory subdir
        end

        @renamedFiles = {}
    end
end

# Script start

if ARGV.length != 1
    puts "Usage\n\nXCImageAssetsCleaner [/path/to/Images.xcassets]"
end

xcassets = ARGV[0]

if File.exist?(xcassets) && File.directory?(xcassets)
    cleaner = XCImageAssetsCleaner.new
    cleaner.clean xcassets
else
    puts "Given XCAssets folder does not exist"
end
