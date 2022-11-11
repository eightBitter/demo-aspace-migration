require 'json'
require 'erb'

def get_data(path,file)
  data = JSON.parse(File.read(File.join(path,file)))
end

def get_template(path,file)
  template = File.read(File.join(path,file))
end

class Record
  include ERB::Util
  attr_accessor :data, :template

  def initialize(data, template)
    @data = data
    @template = template
  end

  def render
    binded = ERB.new(@template).result(binding)
  end

  def save(path,file)
    file_path = File.join(path,file)
    File.open(file_path, "w+") do |f|
      f.write(render)
    end
  end

end

in_path = File.expand_path("~/Documents/migrations/aspace/demo-migration/demo-aspace-migration/data/endpoint")
out_path = File.expand_path("~/Documents/migrations/aspace/demo-migration/demo-aspace-migration/aspace-client-tasks/aspace_client/templates/utilities/data")
template_path = File.expand_path("~/Documents/migrations/aspace/demo-migration/demo-aspace-migration/aspace-client-tasks/aspace_client/templates")

record = Record.new(get_data(in_path,'subjects.json')[0],get_template(template_path,'subjects.json.erb'))

record.save(out_path,'subject_templated.json')