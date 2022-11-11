require_relative '../aspace_client'

class Chains < Thor

  desc 'example_save_chain', 'this represents a sample chain that results in saving output'
  def example_save_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    data = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'registries:save', [registry[:path],'resources_out_subjects_test.json',data]
  end

  desc 'example_post_chain', 'this represents a sample chain that results in posting the output to the API'
  def example_post_chain
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    data = execute 'common:subjects:attach_subjects', [data,"subjects"]
    execute 'common:objects:post_resources', [data,'resources']
  end

  desc 'agents_post', 'ingesting agents via API'
  def agents_post
    registry = execute 'registries:names'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    execute 'common:agents:post_people', [data,'people']
  end

  desc 'subjects_post', 'ingesting subjects via API'
  def subjects_post
    registry = execute 'registries:subjects'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    execute 'common:subjects:post_subjects', [data,'subjects']
  end

  desc 'resources_post', 'ingesting resources via API'
  def resources_post
    registry = execute 'registries:resources'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    execute 'common:objects:post_resources', [data,'resources']
  end

  desc 'objects_attach_all', 'attaching resources, agents, and subjects to objects'
  def objects_attach_all
    registry = execute 'registries:objects'
    data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    data = execute 'common:objects:attach_resources', [data,'collection_id']
    data = execute 'common:agents:attach_people', [data,'name','subject']
    data = execute 'project_name:subjects:attach_subjects', [data,'category']
    # binding.pry
    execute 'registries:save', [registry[:path],'objects_with_attachments.json',data]
  end

  desc 'objects_post', 'ingesting archival objects via API'
  def objects_post
    registry = execute 'registries:objects'
    data = execute 'registries:get_json', [registry[:path],'objects_with_attachments.json']
    execute 'common:objects:post_aos', [data,'aos']
  end

  desc 'hierarchical_objects_post', 'ingesting hierarchical archival objects via API'
  def hierarchical_objects_post
    registry = execute 'registries:objects'
    data = execute 'registries:get_json', [registry[:path],'hierarchy_records.json']
    data = execute 'common:objects:attach_resources', [data,'resource_id']
    execute 'common:objects:post_aos', [data,'hierarchical_aos']
  end

  desc 'build_hierarchy', 'build hierarchy object records for demo'
  def build_hierarchy
    path = File.expand_path("~/Documents/migrations/aspace/demo-migration/demo-aspace-migration/data/endpoint")
    data = execute 'registries:get_csv', [path,'hierarchy_keys.csv']
    # binding.pry
    data = execute 'project_name:hierarchy:build_hierarchy', [data]

    File.write(File.join(path,'hierarchy_records.csv'), data.map {|row| row.join(",")}.join("\n"))
  end

  desc 'link_children_to_parents', 'link child archival object to parent archival object'
  def link_children_to_parents
    registry = execute 'registries:objects'
    item_data = execute 'registries:get_json', [registry[:path],registry[:infile]]
    hierarchy_data = execute 'registries:get_json', [registry[:path],'hierarchy_records.json']
    data = item_data + hierarchy_data

    execute 'project_name:objects:move_aos_child_to_parent', [data,'parent_id']
  end

  desc 'delete_all', 'delete all the records that are in this project'
  def delete_all
    execute 'common:objects:delete_aos'
    execute 'common:objects:delete_resources'
    execute 'common:agents:delete_people'
    execute 'common:subjects:delete_subjects'
  end

  desc 'post_all_the_things', 'run all the post tasks in chains'
  def post_all_the_things
    puts "posting agents"
    execute 'chains:agents_post'
    puts "posting subjects"
    execute 'chains:subjects_post'
    puts "posting resources"
    # resets the API repository to the default
    Aspace_Client.client.repository(2)
    execute 'chains:resources_post'
    puts "attaching entities to item-level objects"
    execute 'chains:objects_attach_all'
    # resets the API repository to the default
    Aspace_Client.client.repository(2)
    puts "posting item-level objects"
    execute 'chains:objects_post'
    puts "posting hierarchical objects"
    execute 'chains:hierarchical_objects_post'
    puts "reorganizing children objects under parent objects"
    execute 'chains:link_children_to_parents'
  end


end
