module Demo
  module Jobs
    module Objects
      extend self

      def resources
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__resources,
            destination: :target__resources_json_out
          },
          transformer: {
          }
        )
      end   

      def objects
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__objects,
            destination: :target__objects_json_out
          },
          transformer: objects_logic
        )
      end  
      
      def objects_logic
        Kiba.job_segment do
          
          # splitters
          transform Transforms::StringValue::ToArray, fields: %i[name category]
          transform Transforms::StringValue::ToArray, fields: %i[date end_date], delim: '/'

          # generate parent hierarchy key
          transform Transforms::Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
            sourcefieldmap: {collection_id: 'ri', record_group: 'rg', record_sub_group: 'rsg', record_series: 'rs', record_sub_series: 'rss'},
            datafield: :parent_id,
            typefield: :hierarchy_type,
            targetsep: '^',
            delete_sources: false

          # custom transform to reformat dates
          transform do |row|
            add_zeros = ->(num){num.length == 1 ? "0#{num}" : num}
            
            begin_date = row[:date].map {|num| add_zeros.call(num)} unless row[:date][0].nil?
            end_date = row[:end_date].map {|num| add_zeros.call(num)} unless row[:end_date][0].nil?
            begin_date = "#{begin_date[2]}-#{begin_date[0]}-#{begin_date[1]}" unless row[:date][0].nil?
            end_date = "#{end_date[2]}-#{end_date[0]}-#{end_date[1]}" unless row[:end_date][0].nil?

            row[:date] = row[:date][0].nil? ? nil : begin_date
            row[:end_date] = row[:end_date][0].nil? ? nil : end_date
            row
          end

        end
      end

      def hierarchy_keys
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__objects,
            destination: :target__hierarchy_keys
          },
          transformer: hierarchy_keys_logic
          )
      end

      def hierarchy_keys_logic
        Kiba.job_segment do
          transform Delete::FieldsExcept, fields: %i[collection_id record_group record_sub_group record_series record_sub_series]
          transform Transforms::Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
            sourcefieldmap: {collection_id: 'ri', record_group: 'rg', record_sub_group: 'rsg', record_series: 'rs', record_sub_series: 'rss'},
            datafield: :hierarchy_key,
            typefield: :hierarchy_type,
            targetsep: '^',
            delete_sources: false
          transform Deduplicate::Table, field: :hierarchy_key
        end
      end

      def hierarchy_records
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__hierarchy_records,
            destination: :target__hierarchy_records
          },
          transformer: {}
        )
      end

    end
  end
end
