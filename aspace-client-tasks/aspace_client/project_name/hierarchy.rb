module Project_Name
  class Hierarchy < Thor

    desc 'build_hierarchy DATA', 'Builds hierarchy object records using hierarchy keys. DATA is array of arrays'
    def build_hierarchy(data)
      id_generator = ->(hierarchy_key,level){
        hierarchy_key.split("^").take(level).join("^")
      }

      csv = [["title","record_type","identifier","resource_id","parent_id","hierarchy_key",]]
  
      ids = []

      data[1..].each do |row|
        # unless record_sub_group is nil
        unless row[4].nil? 
          csv << [row[4],data[0][4],id_generator.call(row[5],5),row[0],id_generator.call(row[5],4),row[5]]
        end
        # unless record_sub_series is nil
        unless row[3].nil?
          # unless the parent id already exists in ids
          # this prevents duplicative parent records
          # from being generated
          unless ids.include?(id_generator.call(row[5],4))
            csv << [row[3],data[0][4],id_generator.call(row[5],4),row[0],id_generator.call(row[5],3),row[5]]
            ids << id_generator.call(row[5],4)
          end
        end
        # unless record_series is nil
        unless row[2].nil?
          # unless the parent id already exists in ids
          # this prevents duplicative parent records
          # from being generated
          unless ids.include?(id_generator.call(row[5],3))
            csv << [row[2],data[0][2],id_generator.call(row[5],3),row[0],id_generator.call(row[5],2),row[5]]
            ids << id_generator.call(row[5],3)
          end
        end
        # unless record_group id already exists in ids
        # this prevents duplicative record_group record
        # from being generated
        unless ids.include?(id_generator.call(row[5],2))
          csv << [row[1],data[0][1],id_generator.call(row[5],2),row[0],"",row[5]]
          ids << id_generator.call(row[5],2)
        end
      end

      return csv
    end

  end
end