module Demo
  module Jobs
    module Entities
      extend self

      def names
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__names,
            destination: :target__names_json_out
          },
          transformer: {
            
          }
        )
      end   

      def subjects
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__subjects,
            destination: :target__subjects_json_out
          },
          transformer: subjects_logic
        )
      end  
      
      def subjects_logic
        Kiba.job_segment do
          # splitters
          transform Transforms::StringValue::ToArray, fields: %i[subject], delim: '~'

        end
      end

    end
  end
end
