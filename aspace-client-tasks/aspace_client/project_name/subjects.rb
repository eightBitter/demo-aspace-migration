module Project_Name
  class Subjects < Thor
    desc "attach_subjects", "attach subjects refs to object by matching values from the given field. assumes DATA is an array of hashes, FIELD is a string"
    def attach_subjects(data,field)
      index = execute "common:subjects:make_index"
      data.each do |record|
        # sets the variable to empty array if the referenced array is nil; otherwise sets the variable to the array
        # this makes it so that this doesn't override the array if it already exists - it would instead add to the array
        subjects_refs = record["subjects__refs"].nil? ? [] : record["subjects__refs"]
        record[field].each {|entity| subjects_refs << index[entity.gsub('~','--')]}
        record["subjects__refs"] = subjects_refs
      end

      data
    end

  end
end