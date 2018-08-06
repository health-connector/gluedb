`cd /var/www/deployments/gluedb/current/`
`rm -rf source_xmls/ > /dev/null`
`unzip -P 'connector' source_xmls.zip`
`echo "Total XMLs for transform"`
`ls source_xmls/ | wc -l`
`sed -i 's/EdiCodec::X12::BenefitEnrollment/EdiCodec::Cv1::Cv1Builder/' script/transform_edi_files.rb`
`rm -rf transformed_x12s/ > /dev/null`
`mkdir transformed_x12s`
`bundle exec rails r script/transform_edi_files.rb -e production`
`rm -rf transformed_cv1s/ > /dev/null`
`mkdir transformed_cv1s`
`mv transformed_x12s/* transformed_cv1s`
`sed -i 's/EdiCodec::Cv1::Cv1Builder/EdiCodec::X12::BenefitEnrollment/' script/transform_edi_files.rb`
`rm -rf transformed_x12s/ > /dev/null`
`mkdir transformed_x12s`
`bundle exec rails r script/transform_edi_files.rb -e production`
`zip -er -P 'connector' transforms_x12s_cv1s_source_xmls.zip transformed_x12s/ transformed_cv1s/ source_xmls/`
`rm -rf source_xmls/ > /dev/null`
`rm -rf transformed_x12s/ > /dev/null`
`rm -rf transformed_cv1s/ > /dev/null`
`rm -v source_xmls.zip`