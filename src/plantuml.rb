require "jsduck/tag/tag"
require "digest/md5"

class PlantUML < JsDuck::Tag::Tag
  def initialize
    @tagname = :plantuml
    @pattern = "plantuml"
    @html_position = POS_DOC + 0.1
    @repeatable = true
  end

  def parse_doc(scanner, position)
    name = scanner.match(/.*$/).strip
    return { :tagname => :plantuml, :name => name, :doc => :multiline }
  end

  def process_doc(context, tags, position)
    context[:plantuml] = tags
  end

  def format(context, formatter)
    output_dir = formatter.instance_variable_get(:@opts).output_dir
    context[:plantuml].each do |plantuml|
      plantuml[:output_dir] = output_dir
    end
  end

  def to_html(context)
    cmd = "env ADDITIONAL_OPTIONS=\"-Djava.awt.headless=true\" plantuml -pipe"
    context[:plantuml].map do |plantuml|
      src = "@startuml\n#{plantuml[:doc]}\n@enduml\n"
      md5 = Digest::MD5.hexdigest(src)
      img = "plantuml/#{md5}.png"
      if !FileTest.exist?(img)
        IO.popen(cmd, "r+") do |io|
          io.print(src)
          io.close_write
          dest = "#{plantuml[:output_dir]}/#{img}"
          dir = File.dirname(dest)
          Dir.mkdir(dir) unless FileTest.directory?(dir)
          open(dest, "wb") do |out|
            out.write(io.read)
          end
        end
      end
      hdr = ""
      hdr += "<h4>#{plantuml[:name]}</h4>" if plantuml[:name] != ""
      "#{hdr}<img src=\"#{img}\">"
    end
  end
end
