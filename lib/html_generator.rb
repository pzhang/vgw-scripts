require 'date'
require 'time'
require 'ftools'
class HTMLGenerator
  attr_accessor :search_dir
  def initialize(dir)
    @search_dir = File.expand_path(dir)
  end
  def make_all_pages(destination = ".", summary_data = {}, path_list = [], options = {})
    destination = File.expand_path(destination)
    File.makedirs(destination)
    Dir.chdir(destination)
    dirlist = Dir.glob("*")
    if options[:regenerate_index] != false
      File.open(File.join(destination, "index.html"), "w") do |f|
        doc = generate_index(dirlist, summary_data, path_list)
        f.write(doc)
      end
    end
    File.open(File.join(destination,
              DateTime.now.strftime("%m_%d_%Y")) + ".html", "w") do |f|
      doc = generate_page(path_list, :summary_data => summary_data)
      f.write(doc)
    end

  end
  #deprecated: this does the same things as the first part of generate index
  def  generate_page(list, options = {})
    doc = "<p> Graphs for #{options[:date]}" if options[:date]
    doc ||= " "
    doc += generate_result_table(list, options[:summary_data])
    return page_gen(doc)
  end

  def generate_result_table(path_hash, summary_data = {})
    doc = ""
    path_hash.each_pair do |k, list|
      unless list.empty?
        doc += "<p style = \"text-align:" + 
               "center\"><b> #{k.capitalize} Data </b></p>"
      end
      doc += "<div style = \"text-align: center\"><table><tr>"
      c = 0
      sum_list = list.dup
      list.each do |l|
        doc += "<td><img src = \"#{l}\" height = \"250\" width = \"250\"/></td>"
        if (c % 3 == 2)
          doc += "</tr><tr>" 
          3.times do |i|
            doc += "<td>"
            doc += "<table><tr>"
            d = 0 
            summary_data[sum_list.shift].each_pair do |k, v|
              doc += "<td><p style = \"font-size: 55%\"><b>#{k} : </b></p>"
              v.each_pair do |k1, v1|
                doc += "<p style = \"font-size:55%\" >#{k1} : #{v1}</p>"
              end
              doc += "</td>"
              doc += "</tr><tr>" if (d % 2 == 1)
              d += 1
            end
            doc += "</table>"
            doc += "</td>"
          end
          doc += "</tr><tr>"
        end
        c += 1
      end
      doc += "</tr></table></div>"
    end
    return doc
  end

  def generate_index(list, summary_data = {}, img_list = [])
    doc = ""
    doc = "<p> Graphs for #{DateTime.now.strftime("%m/%d/%Y")}</p>"
    doc += generate_result_table(img_list, summary_data)
    doc += "<p style =\"text-align: center\"> Data for other days </p> "
    list.each do |l|
      doc += "<p style = \"text-align: center \"><a href = \"#{l}\">#{l}</a></p>"
    end
    return page_gen(doc)
  end
  def page_gen(doc)
    a =  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
         \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
         <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
         <head>
          <meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />
         </head>
          <style type=\"text/css\">
          table
          { 
            margin-left: auto;
            margin-right: auto;
            text-align: left;
          }

          </style
          <title> VGW reporting graphs </title>
          <body>"
    a+= doc
    a += "</body></html>"
    return a
  end
end
