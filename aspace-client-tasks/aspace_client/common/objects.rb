module Common
  class Objects < Thor

    desc 'get_resources', 'retrieve API response of all resource data in ASpace'
    def get_resources(*args)
      page = 1
      data = []
      response = Aspace_Client.client.get('resources', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('resources', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_aos', 'retrieve API response of all resource data in ASpace'
    def get_aos(*args)
      page = 1
      data = []
      response = Aspace_Client.client.get('archival_objects', query: {page: page, page_size: 100})
      last_page = response.result['last_page']
      while page <= last_page
        response = Aspace_Client.client.get('archival_objects', query: {page: page, page_size: 100})
        data << response.result['results']
        page += 1
      end
      data.flatten
    end

    desc 'get_aos_all_ids', 'retrieve API response of all archival object ids. returns an array of integers'
    def get_aos_all_ids(*args)
      response = Aspace_Client.client.get('archival_objects', query: {all_ids: true})
      data = response.result
    end

    desc 'get_resources_all_ids', 'retrieve API response of all resource ids. returns an array of integers'
    def get_resources_all_ids(*args)
      response = Aspace_Client.client.get('resources', query: {all_ids: true})
      data = response.result
    end

    desc 'make_index_resources', 'create the following index - "id_0:uri"'
    def make_index_resources(*args)
      data = execute 'common:objects:get_resources'
      index = {}
      data.each do |record|
        index[record['id_0']] = record['uri']
      end
      index
    end

    desc 'make_index_aos', 'create the following index - "component_id:uri"'
    def make_index_aos(*args)
      data = execute 'common:objects:get_aos'
      index = {}
      data.each do |record|
        index[record['component_id']] = record['uri']
      end
      index
    end

    desc 'post_resources DATA, TEMPLATE', 'given data and template filename (no extension), ingest resources via the ASpace API'
    def post_resources(data,template)
      
      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('resources', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'post_aos DATA, TEMPLATE', 'given data and template filename (no extension), ingest archival objects via the ASpace API'
    def post_aos(data,template)

      # setting up error log
      log_path = Aspace_Client.log_path
      error_log = []

      data.each do |row|
        json = ArchivesSpace::Template.process(template.to_sym, row)
        response = Aspace_Client.client.post('archival_objects', json)
        puts response.result.success? ? "=) #{data.length - data.find_index(row) - 1} to go" : response.result
        error_log << response.result if response.result.success? == false
      end
      write_path = File.join(log_path,"post_aos_error_log.txt")
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end
    end

    desc 'delete_aos', 'delete all archival objects via API'
    def delete_aos
      # shape: [1,2,3]
      data = execute 'common:objects:get_aos_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("archival_objects/#{id}")
        puts response.result.success? ? "=) #{data.length - data.find_index(id) - 1} to go" : response.result
      end
    end

    desc 'delete_resources', 'delete all resources via API'
    def delete_resources
      # shape: [1,2,3]
      data = execute 'common:objects:get_resources_all_ids'
      data.each do |id|
        response = Aspace_Client.client.delete("resources/#{id}")
        puts response.result.success? ? "=) #{data.length - data.find_index(id) - 1} to go" : response.result
      end
    end

    desc "attach_resources DATA, FIELD", "attach resource ref to object by matching values from the given field. assumes DATA is an array of hashes, FIELD is a string"
    def attach_resources(data,field)
      index = execute "common:objects:make_index_resources"
      # ::Kernel.binding.pry
      data.each do |record|
        # record[field].each {|entity| subjects_refs << index[entity]}
        record["resource__ref"] = index[record[field]]
      end

      data
    end

    desc 'update_resources_with_data DATA, ID', 'given a dataset and ID field, update existing resource records, matching on identifier'
    def update_resources_with_data(data,id)
      puts "making index..."
      index = execute 'common:objects:make_index_resources'
      puts "getting resources..."
      resources = execute 'common:objects:get_resources'
      log_path = Aspace_Client.log_path
      error_log = []
      nonmatched_identifiers = []

      puts "updating resources..."
      resources.each do |resource|
        # find the first occurrence of a match then move on
        matching_data = data.lazy.select {|record| record['accessno'] == resource['id_0']}.first(1)
        # binding.pry
        # turn the hash into templated json
        if matching_data[0] == nil
          nonmatched_identifiers << resource['accessno']
        else
          json = ArchivesSpace::Template.process(:resources,matching_data[0])
          # turn it back into a hash so you can merge it with the API data
          templated_data = JSON.parse(json)
          templated_data['subjects'] = templated_data['subjects'].concat resource['subjects']
          # conditionally adds linked_agent objects from resource to templated_data if they're not already in templated_data
          # mitigates potential duplication issues
          resource['linked_agents'].each do |linked_agent|
            unless templated_data['linked_agents'].map{|agent| agent['ref']}.include? linked_agent['ref']
              templated_data['linked_agents'] << linked_agent
            end
          end
          resource.merge!(templated_data)
          # breaking up the record's uri so you can programmatically post to the appropriate record
          ref_split = index[resource['id_0']].split('/')
          response = Aspace_Client.client.post("#{ref_split[3]}/#{ref_split[4]}",resource.to_json)
          puts response.result.success? ? "=) #{resources.length - (resources.find_index(resource) + 1)} to go" : response.result
          error_log << response.result if response.result.success? == false
        end
      end

      write_path = File.join(log_path,"update_resources_error_log.txt")
      write_path_nonmatched_identifiers = File.join(log_path,"update_resources_nonmatched_identifiers.txt")
      
      File.open(write_path,"w") do |f|
        f.write(error_log.join(",\n"))
      end

      File.open(write_path_nonmatched_identifiers,"w") do |f|
        f.write(nonmatched_identifiers.join(",\n"))
      end

    end

  end
end
