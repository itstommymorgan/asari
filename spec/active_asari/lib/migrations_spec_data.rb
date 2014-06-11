module MigrationsSpecData

  CREATE_DOMAIN_RESPONSE = {:domain_status=>{:search_partition_count=>0, :search_service=>{:arn=>"arn:aws:cs:us-east-1:888167492042:search/beavis"}, :num_searchable_docs=>0, :created=>true, :domain_id=>"888167492042/beavis", :processing=>false, :search_instance_count=>0, :domain_name=>"beavis", :requires_index_documents=>false, :deleted=>false, :doc_service=>{:arn=>"arn:aws:cs:us-east-1:888167492042:doc/beavis"}}, :response_metadata=>{:request_id=>"88e3adcb-f999-11e2-ba8b-ab9a7c0903a8"}}
  CREATE_LITERAL_INDEX_RESPONSE = {:index_field=>{:status=>{:creation_date=>'2013-07-30 20:47:55 UTC', :pending_deletion=>"false", :update_version=>20, :state=>"RequiresIndexDocuments", :update_date=>'2013-07-30 20:47:55 UTC'}, :options=>{:source_attributes=>[], :literal_options=>{:search_enabled=>false}, :index_field_type=>"literal", :index_field_name=>"test"}}, :response_metadata=>{:request_id=>"8885505e-f959-11e2-b89b-2d5c6f978750"}}
  CREATE_TEXT_INDEX_RESPONSE = {:index_field=>{:status=>{:creation_date=>'2013-07-30 20:47:55 UTC', :pending_deletion=>"false", :update_version=>20, :state=>"RequiresIndexDocuments", :update_date=>'2013-07-30 20:47:55 UTC'}, :options=>{:source_attributes=>[], :text_options=>{:result_enabled=>true}, :index_field_type=>"text", :index_field_name=>"test"}}, :response_metadata=>{:request_id=>"8885505e-f959-11e2-b89b-2d5c6f978750"}}
  CREATE_UINT_INDEX_RESPONSE = {:index_field=>{:status=>{:creation_date=>'2013-07-30 20:47:55 UTC', :pending_deletion=>"false", :update_version=>20, :state=>"RequiresIndexDocuments", :update_date=>'2013-07-30 20:47:55 UTC'}, :options=>{:source_attributes=>[], :index_field_type=>"int", :index_field_name=>"num_tvs"}}, :response_metadata=>{:request_id=>"8885505e-f959-11e2-b89b-2d5c6f978750"}}
end


