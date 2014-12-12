require 'csv'
#require 'ruby-prof'

namespace :edi do
  namespace :import do
    def with_progress_bar(file, message)
      fs = File.size(file)
      f = File.open(file)
      pb = ProgressBar.create(
        :title => "Loading #{message}",
        :total => fs,
        :format => "%t %a %e |%B| %P%%"
      )
      CSV.foreach(f, :headers => true) do |data|
        yield data, pb
        pb.progress += data.to_s.length
      end
      pb.finish
    end

    def import_bgn_blacklist
      bgn_list = []
      bl_file = File.join(Rails.root, "db", "data", "bgn_blacklist.csv")
      return bgn_list unless File.exist?(bl_file)
      blf = File.open(bl_file, "r")
      blf.each_line do |line|
        lval = line.strip
        if !lval.blank?
          bgn_list << lval
        end
      end
      blf.close
      bgn_list
    end

    desc "Import outbound 820s from the exported EDI"
    task :outbound_820 => :environment do
      f = File.join(Rails.root, "db", "data", "b2b_outbound_820.csv")
      with_progress_bar(f, "820s") do |row|
        record = row.to_hash
        f_name = record['PROTOCOLMESSAGEID']
        p = Parsers::Edi::RemittanceTransmission.new(f_name, record['WIREPAYLOADUNPACKED'])
        p.persist!
      end
    end

    desc "Import it all from the JSONs"
    task :all => :environment do
      bgn_blacklist = import_bgn_blacklist
      f = File.join(Rails.root, "db", "data", "all_json.csv")
      ic = Parsers::Edi::ImportCache.new
      Caches::HiosCache.allocate
      Caches::MongoidCache.allocate(Plan)
#     RubyProf.start
      with_progress_bar(f, "ie 834s") do |row, pb|
        record = row.to_hash
        f_name = record['PROTOCOLMESSAGEID']
        trans_kind = record['TRANSTYPE']
        case trans_kind
        when "999"
          p = Parsers::Edi::TransactionSetResult.new(f_name, record['WIREPAYLOADUNPACKED'])
          p.persist!
        when "TA1"
          p = Parsers::Edi::TransmissionResponse.new(f_name, record['WIREPAYLOADUNPACKED'])
          p.persist!
        when "820"
          p = Parsers::Edi::RemittanceTransmission.new(f_name, record['WIREPAYLOADUNPACKED'], ic, pb)
          p.persist!
        else
          p = Parsers::Edi::TransmissionFile.new(f_name, trans_kind, record['WIREPAYLOADUNPACKED'], bgn_blacklist, ic, pb)
          p.persist!
        end
      end
#      result = RubyProf.stop
#      printer = RubyProf::GraphHtmlPrinter.new(result)
#      r_file = File.open('profile.html', 'w')
#      printer.print(r_file)
#      r_file.close
      Caches::HiosCache.release
      Caches::MongoidCache.release(Plan)
    end
  end
end
