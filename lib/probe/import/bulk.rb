module Probe
  class Import
    class Bulk < Probe::Import
      def import
        each_slice(options[:batch_size] || 1000) do |documents|
          request = documents.map do |document|
            [
              { action => { _index: index.name, _type: index.type, _id: document.id }},
              document_for_import(document)
            ]
          end.flatten

          client.bulk body: request
        end
      end
    end
  end
end
